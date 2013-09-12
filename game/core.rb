require './world/factories'
require './game/tables'
require './game/object_extensions'
require './game/character_loader'
require './raws/db'
require './knowledge/raw_kb'
require './util/exceptions'
require './util/packer'

class GameCore
    include Packer

    def self.packable; [:tick_rate]; end

    attr_reader :world, :db, :kb

    def initialize
        Message.setup(self)

        @usage_mutex     = Mutex.new

        @uid_count            = 0
        @awaiting_destruction = []
        @object_manifest      = {}
        object_manifest_types.each do |klass|
            @object_manifest[klass] = {}
        end

        @ticking              = false
    end

    def pack_custom(hash)
        @usage_mutex.synchronize do
            Log.info("Saving game core")

            hash[:db]              = ObjectDB.pack(@db)
            hash[:kb]              = ObjectKB.pack(@kb)
            hash[:words_db]        = WordDB.pack(@words_db)

            hash[:object_manifest] = {}
            @object_manifest.keys.each do |klass|
                Log.debug("Packing #{klass} manifest")
                hash[:object_manifest][klass] = {}
                @object_manifest[klass].each do |uid, obj|
                    hash[:object_manifest][klass][uid] = klass.pack(obj)
                end
            end

            hash[:world_uid]       = @world.uid

            hash[:managers]        = pack_managers
        end
        hash
    end

    def unpack_custom(hash)
        @usage_mutex.synchronize do
            Log.info("Loading game core")

            # Unpack raws
            # -------------------------------
            @db = ObjectDB.unpack(hash[:db])
            @kb = ObjectKB.unpack(@db, hash[:kb])
            @words_db = WordDB.unpack(hash[:words_db])

            # Unpack objects
            # -------------------------------
            @uid_count = 0
            uid_max = 0
            Log.debug("Unpacking #{object_manifest_types.size} object manifest types from #{hash[:object_manifest].keys.inspect}")
            object_manifest_types.each do |klass|
                manifest = hash[:object_manifest][klass]
                Log.debug("Unpacking #{manifest.keys.size} #{klass} types")
                hash[:object_manifest][klass].each do |uid,obj_hash|
                    @uid_count += 1
                    uid_max = [uid_max, uid].max
                    @object_manifest[klass][uid] = klass.unpack(self, obj_hash)
                    Log.debug("Unpacked #{uid}")
                end
            end
            raise(UnexpectedBehaviorError, "UID counts do not match (too few or too many UIDs loaded)") if @uid_count != uid_max
            Log.debug("Found #{@uid_count} uids")

            # Unpack world
            # -------------------------------
            if @object_manifest.has_key?(World)
                worlds = @object_manifest[World].keys
                raise(UnexpectedBehaviorError, "#{worlds.size == 0 ? "No" : "Multiple"} world objects present") if worlds.size != 1
                raise(UnexpectedBehaviorError, "World UID is inconsistent") if worlds.first != hash[:world_uid]
                @world = hash[:world_uid]
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
        @usage_mutex.synchronize do
            Log.info("Setting up game core")

            # Setup various game variables
            # ----------------------------
            @tick_rate = args[:tick_rate] || (30)

            # Read the raws
            # -------------
            raw_group = args[:raw_group] || "default"
            @db       = ObjectDB.get(raw_group)
            @kb       = ObjectKB.new(@db, true)
            @words_db = WordParser.load
            WordParser.read_raws(@words_db, @db)

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
        @usage_mutex.synchronize do
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
        @usage_mutex.synchronize do
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
        Log.debug("Looking up #{uid}", 9)
        object_manifest_types.each do |klass|
            return @object_manifest[klass][uid] if @object_manifest[klass].has_key?(uid)
            Log.debug("Not found in #{klass}", 9)
        end
        raise("Unknown UID #{uid}")
    end

    def flag_for_destruction(object, destroyer)
        @awaiting_destruction << [object, destroyer]
    end

    def destroy_flagged
        Log.debug("Destroying flagged objects")
        destroyed = []

        until @awaiting_destruction.empty?
            to_destroy = @awaiting_destruction.dup
            @awaiting_destruction = []
            Log.debug("#{to_destroy.size} objects flagged for destruction")
            until to_destroy.empty?
                next_to_destroy, destroyer = to_destroy.shift
                next if destroyed.include?(next_to_destroy)

                next_to_destroy.destroy(destroyer)
                @object_manifest[BushidoObject].delete(next_to_destroy.uid)

                destroyed << next_to_destroy
            end
        end
    end

    # TICK MAINTENANCE
    # ================
    def start_ticking
        already_ticking = false
        @usage_mutex.synchronize do
            already_ticking = @ticking
            @ticking = true
        end

        raise(StateError, "Already ticking.") if already_ticking

        Thread.new do
            Log.name_thread("Tick")
            begin
                keep_ticking = true
                while keep_ticking
                    sleep(@tick_rate)
                    @usage_mutex.synchronize do
                        dispatch_ticks
                        keep_ticking = @ticking
                    end
                end
            rescue Exception => e
                Log.debug(["Terminating abnormally", e.message, e.backtrace])
            end
            Log.debug("Ticking halted")
        end
    end

    def stop_ticking
        @usage_mutex.synchronize do
            @ticking = false
        end
    end

    def protect(&block)
        @usage_mutex.synchronize do
            yield
        end
    end

    # CHARACTER MAINTENANCE
    # =====================
    def load_character(lobby, username, character_name)
        ret = nil
        @usage_mutex.synchronize do
            cached_positions[username]

            character, failures = CharacterLoader.attempt_to_load(self, username, character_name)
            if character
                starting_location = cached_positions[username]
                unless starting_location
# TODO - Find a better way to determine random starting locations for players
=begin
                    spawn_location_types = @population_manager[character.get_type][:spawns]
                    starting_location    = @world.get_random_location(spawn_location_types)
=end
                    starting_location  ||= @world.get_random_location
                end
                character.set_initial_position(starting_location)
                character.set_user_callback(lobby, username)

                characters[username] = character
                Log.info("Character #{character.monicker} loaded for #{username}")
            end

            ret = [character, failures]
        end
        return ret
    end
    def get_user_characters(username)
        CharacterLoader.get_characters_for(username)
    end
    def has_active_character?(username)
        characters.has_key?(username)
    end
    def get_character(username)
        characters[username]
    end
    def get_character_user(character)
        ret = nil
        characters.each do |k,v|
            if v == character
                ret = k
                break
            end
        end
        return ret
    end
    def remove_character(username, character_dies=false)
        character = characters[username]

        if character_dies
            cached_positions[username] = nil
            # TODO - We should determine what happens when a character is killed - can he reload his last save, or must he start a new character?
        else
            # Cache the character's position within the game server so that it can be placed back where it exited when logging back in
            cached_positions[username] = character.absolute_position
            CharacterLoader.save(username, character)
            character.destroy(nil, true)
        end
        characters.delete(username)
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
        Message.dispatch(self, :tick)
    end

    def characters;       @characters       ||= {}; end
    def cached_positions; @cached_positions ||= {}; end
end
