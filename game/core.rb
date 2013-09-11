require './world/factories'
require './game/tables'
require './game/object_extensions'
require './game/character_loader'
require './raws/db'
require './knowledge/raw_kb'
require './util/exceptions'

class GameCore
    attr_reader :world, :db, :kb

    def initialize
        Message.setup(self)

        @usage_mutex     = Mutex.new

        @object_manifest      = {}
        @uid_count            = 0
        @awaiting_destruction = []

        @ticking              = false
    end

    def pack
        hash = {}
        @usage_mutex.synchronize do
            Log.info("Saving game core")

            hash[:tick_rate]       = @tick_rate

            hash[:db]              = ObjectDB.pack(@db)
            hash[:kb]              = ObjectKB.pack(@kb)
            hash[:words_db]        = WordParser.pack(@words_db)

            hash[:object_manifest] = {}
            @object_manifest.each do |k,v|
              hash[:object_manifest][k] = BushidoObject.pack(k)
            end

            hash[:world]           = pack_world

            hash[:managers]        = pack_managers
        end
        hash
    end

    def unpack(hash)
        @usage_mutex.synchronize do
            Log.info("Loading game core")

            # Unpack tick rate
            # -------------------------------
            @tick_rate = hash[:tick_rate]

            # Unpack raws
            # -------------------------------
            @db = ObjectDB.unpack(hash[:db])
            @kb = ObjectKB.unpack(hash[:kb])
            @words_db = WordParser.unpack(hash[:words_db])

            # Unpack objects
            # -------------------------------
            @uid_count = hash[:object_manifest].keys.max
            hash[:object_manifest].each do |k,v|
                @object_manifest[k] = BushidoObject.unpack(self, v)
            end

            # Unpack world
            # -------------------------------
            unpack_world(hash[:world])

            # Unpack the world object managers
            # -------------------------------
            unpack_managers(hash[:managers])

            @setup = true
        end
    end

    # PUBLIC (THREADSAFE) METHODS
    def setup(args)
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

    def next_uid
        @uid_count += 1
    end

    # CREATION AND DESTRUCTION
    # ========================
    def create(type, hash = {})
        obj_uid = next_uid
        obj = @db.create(self, type, obj_uid, hash)
        @object_manifest[obj_uid] = obj
        obj
    end

    def lookup(uid)
        raise("Unknown UID #{uid}") unless @object_manifest.has_key?(uid)
        @object_manifest[uid]
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
                @object_manifest.delete(next_to_destroy.uid)

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
    def pack_world
        raise(NotImplementedError, "Core must be subclassed with pack_world implemented")
    end
    def pack_managers
        raise(NotImplementedError, "Core must be subclassed with pack_managers implemented")
    end
    def unpack_world(hash)
        raise(NotImplementedError, "Core must be subclassed with unpack_world implemented")
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
