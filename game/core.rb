require './world/factories'
require './game/tables'
require './game/object_extensions'
require './raws/db'
require './knowledge/raw_kb'
require './util/exceptions'
require './util/packer'

class GameCore
    include Packer

    def self.packable; [:tick_rate, :created_on, :tick_count, :characters, :active_characters, :inactive_objects]; end

    attr_reader :world, :db, :kb, :words_db, :tick_count, :created_on

    def initialize
        Message.setup(self)

        @usage_mutex     = Mutex.new
        @created_on      = Time.now

        @uid_count            = 0
        @awaiting_destruction = []
        @object_manifest      = {}
        object_manifest_types.each do |klass|
            @object_manifest[klass] = {}
        end
        @inactive_objects     = {}
        @characters           = {}
        @active_characters    = {}

        @tick_count           = 0
        @ticking              = false
    end

    # Callback set up for characters to send messages to their respective clients via the lobby
    def set_lobby(value); @lobby = value; end
    def clear_lobby;      @lobby = nil;   end

    def send_with_dialect(username, message_type, properties)
        raise(UnexpectedBehaviorError, "Lobby not set") unless @lobby

        character = get_character(username)
        sanitized_properties = Descriptor.describe(properties.merge(:observer => character, :speaker => :game), character)

        dialect = @lobby.get_user_dialect(username)
        details = case dialect
        when :text
            Descriptor.create_report(message_type, @words_db, sanitized_properties)
        when :metadata
            sanitized_properties
        else
            Log.error("Unknown dialect, #{dialect}, falling back to metadata")
            sanitized_properties
        end

        @lobby.send_to_user(username, Message.new(message_type, {:details => details}))
    end

    def send_to_user(username, message)
        raise(UnexpectedBehaviorError, "Lobby not set") unless @lobby

        character = get_character(username)
        message.alter_params! do |params|
            Descriptor.describe(params.merge(:observer => character, :speaker => :game), character)
        end

        @lobby.send_to_user(username, message)
    end

    def protect(&block)
        @usage_mutex.synchronize do
            yield
        end
    end

    def pack_custom(hash)
        protect do
            Log.info("Saving game core")

            currently_active = @active_characters.values.compact
            Log.warning("Danger: active characters were found during core packing : #{currently_active.inspect}") unless currently_active.empty?

            @saved_on              = Time.now

            hash[:db]              = ObjectDB.pack(@db)
            hash[:kb]              = ObjectKB.pack(@kb)
            hash[:words_db]        = WordDB.pack(@words_db)

            hash[:object_manifest] = {}
            @object_manifest.keys.each do |klass|
                Log.debug("Packing #{klass} manifest")
                hash[:object_manifest][klass] = {}
                @object_manifest[klass].each do |uid, obj|
                    Log.debug("Packing #{uid}", 8)
                    hash[:object_manifest][klass][uid] = klass.pack(obj)
                end
            end

            hash[:world_uid]       = @world.uid

            hash[:managers]        = pack_managers
            Log.info("Done")
        end
        hash
    end

    def unpack_custom(hash)
        protect do
            Log.info("Loading game core")

            # Unpack raws
            # -------------------------------
            @db       = ObjectDB.unpack(hash[:db])
            @kb       = ObjectKB.unpack(@db, hash[:kb])
            @words_db = WordDB.unpack(hash[:words_db])

            # Unpack objects
            # -------------------------------
            uid_max             = 0
            uids_present        = []
            Log.debug("Unpacking #{object_manifest_types.size} object manifest types from #{hash[:object_manifest].keys.inspect}")
            object_manifest_types.each do |klass|
                manifest = hash[:object_manifest][klass]
                Log.debug("Unpacking #{manifest.keys.size} #{klass} types")
                hash[:object_manifest][klass].each do |uid,obj_hash|
                    uid_max = [uid_max, uid].max
                    uids_present << uid

                    @object_manifest[klass][uid] = klass.unpack(self, obj_hash)
                    Log.debug("Unpacked #{uid}", 8)
                end
            end
            missing_uids = (1..uid_max).to_a - uids_present

            @characters.each do |username, character_hash|
                Log.debug("Checking for active character for #{username} (#{character_hash.size} total)")
                active_uid = active_character(username)
                Log.warning("Danger: active character #{active_uid} found during world unpacking") if active_uid
                if missing_uids.include?(active_uid)
                    Log.error("Weirdness - an active character's UID is marked as missing")
                end
                character_hash.keys.each do |uid|
                    next if active_uid == uid
                    unless missing_uids.include?(uid)
                        Log.error("Weirdness - an inactive character's UID was loaded")
                    end
                    missing_uids.delete(uid)
                end
            end
            missing_inactive = 0
            @inactive_objects.each do |uid, obj_info|
                if missing_uids.include?(uid)
                    missing_inactive += 1
                    missing_uids.delete(uid)
                end
            end
            Log.debug("#{missing_inactive} missing UIDs resolved within #{@inactive_objects.size} inactive objects")
            raise(UnexpectedBehaviorError, "Missing UIDs: #{missing_uids.inspect}") unless missing_uids.empty?

            @uid_count = uid_max
            Log.debug("Found #{@uid_count} uids")

            # Identify world
            # -------------------------------
            if @object_manifest.has_key?(World)
                worlds = @object_manifest[World].values
                raise(UnexpectedBehaviorError, "#{worlds.size == 0 ? "No" : "Multiple"} world objects present") if worlds.size != 1
                raise(UnexpectedBehaviorError, "World UID is inconsistent") if worlds.first.uid != hash[:world_uid]
                @world = worlds.first
            else
                raise(MissingProperty, "World data corrupt")
            end

            # Unpack the world object managers
            # -------------------------------
            unpack_managers(hash[:managers])

            @setup = true
        end
    end

    # PUBLIC (THREADSAFE) METHODS
    def setup(args={})
        protect do
            Log.info("Setting up game core")

            # Setup various game variables
            # ----------------------------
            @tick_rate = args[:tick_rate] || (30)

            # Read the raws
            # -------------
            raw_group = args[:raw_group] || "default"
            @db       = ObjectDB.get(raw_group)
            @kb       = ObjectKB.new(@db, true)
            @words_db = WordDB.new(@db)

            # Setup the physical world
            # ------------------------
            setup_world(args)

            # Setup the world object managers
            # -------------------------------
            setup_managers(args)

            @setup = true
        end
    end

    def teardown
        protect do
            teardown_managers

            teardown_world

            @db            = nil
            @words_db      = nil
            @ticking       = false

            @setup = false
        end
    end

    def setup?
        ret = nil
        protect do
            ret = @setup
        end
        ret
    end

    private
    def next_uid
        @uid_count += 1
    end

    public
    # CREATION AND DESTRUCTION
    # ========================
    def class_manifest_types
        unless @class_manifest_types
            @class_manifest_types = [Area, Room, World]
            if Object.const_defined?("FakeRoom")
                @class_manifest_types << FakeRoom
            end
        end
        @class_manifest_types
    end
    def object_manifest_types
        unless @object_manifest_types
            @object_manifest_types = class_manifest_types.concat([BushidoObject])
        end
        @object_manifest_types
    end

    def create(type, hash = {})
        obj_uid = next_uid
        klass = nil
        obj   = nil
        if class_manifest_types.include?(type)
            obj   = type.new(self, obj_uid, hash)
            klass = type
        else
            obj   = @db.create(self, type, obj_uid, hash)
            klass = obj.class
        end
        Log.debug("Creating #{type.inspect} (#{klass} | #{obj_uid})", 9)
        @object_manifest[klass] ||= {}
        @object_manifest[klass][obj_uid] = obj
        obj
    end

    def lookup(uid)
        raise(UnexpectedBehaviorError, "Lookup attempted for nil UID") unless uid
        Log.debug("Looking up #{uid}", 9)
        object_manifest_types.each do |klass|
            return @object_manifest[klass][uid] if @object_manifest[klass].has_key?(uid)
            Log.debug("Not found in #{klass}", 9)
        end
        return @inactive_objects[uid] if @inactive_objects.has_key?(uid)
        raise(UnexpectedBehaviorError, "Unknown UID #{uid.inspect}")
    end

    def flag_for_destruction(object, destroyer)
        @awaiting_destruction << [object, destroyer]
    end

    def destroy_flagged
        Log.debug("Destroying flagged objects", 6)
        destroyed = []

        until @awaiting_destruction.empty?
            to_destroy = @awaiting_destruction.dup
            @awaiting_destruction = []
            Log.debug("#{to_destroy.size} objects flagged for destruction", 6)
            until to_destroy.empty?
                next_to_destroy, destroyer = to_destroy.shift
                next if destroyed.include?(next_to_destroy)

                destroyed_uid = next_to_destroy.uid
                next_to_destroy.destroy(destroyer)

                @object_manifest[BushidoObject].delete(destroyed_uid)
                @inactive_objects[destroyed_uid] = BushidoObject.pack(next_to_destroy)

                @active_characters.each do |username, uid|
                    if uid == destroyed_uid
                        @lobby.broadcast(Message.new(:user_dies, {:result => username}))
                        set_active_character(username, nil)
                        break
                    end
                end

                destroyed << next_to_destroy
            end
        end
    end

    # TICK MAINTENANCE
    # ================
    def start_ticking
        already_ticking = false
        protect do
            already_ticking = @ticking
            @ticking = true
        end

        raise(StateError, "Already ticking.") if already_ticking

        Thread.new do
            Log.name_thread("Tick")
            begin
                keep_ticking = true
                while keep_ticking
                    protect { dispatch_ticks }
                    sleep(@tick_rate)
                    protect { keep_ticking = @ticking }
                end
            rescue Exception => e
                Log.debug(["Terminating abnormally", e.message, e.backtrace])
            end
            Log.debug("Ticking halted")
        end
    end

    def stop_ticking
        protect { @ticking = false }
    end

    # CHARACTER MAINTENANCE
    # =====================
    def get_characters_for(username)
        info_hash = {}
        characters(username).each do |uid, info|
            character_info = @inactive_objects[uid].merge(info)
            info_hash[uid] = CharacterInfo.new(character_info)
        end
        info_hash
    end

    def get_character(username)
        character_uid = safe_character(username)
        lookup(character_uid)
    end

    def extract_characters_temporarily
        temp_map = Marshal.load(Marshal.dump(@active_characters))
        Log.debug("Temporarily extracting characters (likely for a game save)")
        @active_characters.each do |username, uid|
            extract_character(username) if uid
        end
        temp_map
    end
    def extract_character(username)
        Log.debug("Extracting #{username.inspect}'s character")
        character_uid = safe_character(username)
        character     = lookup(character_uid)

        packed_character                    = BushidoObject.pack(character)
        characters(username)[character_uid] = {
            :name             => character.name,
            :created_on       => character.created_on,
            :saved_on         => Time.now
        }
        @inactive_objects[character_uid] = packed_character
        @object_manifest[BushidoObject].delete(character.uid)

        set_active_character(username, nil)
        character.extract
        character_uid
    end

    def reinject_characters(temp_map)
        Log.debug("Reinjecting characters")
        temp_map.each do |username, uid|
            inject_character(username, uid)
        end
    end
    def inject_character(username, uid)
        Log.debug("Injecting #{username.inspect} as #{uid.inspect}")
        active_uid = active_character(username)
        raise(UnexpectedBehaviorError, "#{username} already has an active character (#{active_uid.inspect})") if active_uid
        raise(UnexpectedBehaviorError, "#{username} has no character with UID #{uid}") unless characters(username).has_key?(uid)

        info = @inactive_objects[uid]
        character = BushidoObject.unpack(self, info)
        @inactive_objects.delete(uid)
        @object_manifest[BushidoObject][uid] = character

        character.inject
        set_active_character(username, character.uid)
    end

    def active_character(username)
        @active_characters[username]
    end

    # PRIVATE (NOT THREADSAFE) METHODS
    # ================================
    private
    def setup_world(args)
        raise(NotImplementedError, "Core must be subclassed with setup_world implemented")
    end
    def setup_managers(args)
        raise(NotImplementedError, "Core must be subclassed with setup_managers implemented")
    end
    def pack_managers
        raise(NotImplementedError, "Core must be subclassed with pack_managers implemented")
    end
    def unpack_managers(hash)
        raise(NotImplementedError, "Core must be subclassed with unpack_managers implemented")
    end
    def teardown_world
        raise(NotImplementedError, "Core must be subclassed with teardown_world implemented")
    end
    def teardown_managers
        raise(NotImplementedError, "Core must be subclassed with teardown_managers implemented")
    end

    def dispatch_ticks
        @tick_count += 1
        Message.dispatch(self, :tick)
    end

    def characters(username)
        @characters[username] ||= {}
    end

    def safe_character(username)
        character_uid = active_character(username)
        unless character_uid
            raise(UnexpectedBehaviorError, "#{username} has no active character")
        end
        character_uid
    end

    def set_active_character(username, value)
        @active_characters[username] = value
        Log.debug(["Active character of #{username.inspect} set to #{value.inspect}", @active_characters])
    end
end
