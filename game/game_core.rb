require 'world/factories'
require 'game/tables'
require 'game/object_extensions'
require 'raws/db'
require 'message'

class GameCore
    attr_reader :world, :db

    def initialize(args={})
        # TODO - Set this to something much higher once we're out of debug
        @tick_rate        = args[:tick_rate] || (30)
        @ticking          = false
        @ticking_mutex    = Mutex.new

        # Read the raws
        # TODO: Load raw_group from server config?
        raw_group = "default"
        Log.debug("Loading #{raw_group} raws")
        @db = ObjectDB.get(raw_group)

        @words_db = WordParser.load

        create_world(args)
    end

    def create_world(args)
        Log.debug("Creating world")
        @world = WorldFactory.generate(args)

        Log.debug("Populating world with NPCs and items")
        @world.populate(self)
    end

    # TICK MAINTENANCE
    def start_ticking
        already_ticking = false
        @ticking_mutex.synchronize {
            already_ticking = @ticking
            @ticking = true
        }
        raise "Already ticking" if already_ticking
        Thread.new do
            Log.name_thread("Tick Thread")
            begin
                keep_ticking = true
                while keep_ticking
                    @ticking_mutex.synchronize {
                        dispatch_ticks
                        keep_ticking = @ticking
                    }
                    sleep(@tick_rate)
                end
            rescue Exception => e
                Log.debug(["Terminating abnormally", e.message, e.backtrace])
            end
            Log.debug("Ticking halted")
        end
    end
    def stop_ticking
        @ticking_mutex.synchronize {
            @ticking = false
        }
    end
    def dispatch_ticks
        Message.dispatch(self, :tick)
    end

    # CHARACTER MAINTENANCE
    def characters;       @characters       ||= {}; end
    def cached_positions; @cached_positions ||= {}; end
    def load_character(username, character_name)
        cached_positions[username]

        character, failures = Character.attempt_to_load(username, character_name)
        if character
            character.set_position(cached_positions[username] || @world.random_starting_location)
            character.set_core(self)
            characters[username] = character
            Message.register_listener(self, :core, character)
        end

        return [character, failures]
    end
    def create_character(username, character_details)
        begin
            character_details.merge!(:initial_position => @world.random_starting_location)
            character = @db.create(self, :character, character_details)

            characters[username] = character
            Message.register_listener(self, :core, character)

            return true
        rescue Exception => e
            Log.debug(["Failed to create new character", e.message, e.backtrace])
            return false
        end
    end
    def has_active_character?(username)
        characters.has_key?(username)
    end
    def get_character(username)
        characters[username]
    end
    def remove_character(username)
        character = characters[username]

        Message.unregister_listener(self, :core, character)
        cached_positions[username] = character.position
        character.nil_core
        Character.save(username, character)

        characters.delete(username)
    end

    # NPC MAINTENANCE
    # This is mostly here for the message registration and unregistration
    # Without the need to pass messages to NPCs, we probably would not store references to them here at all
    def npcs
        @npcs ||= []
    end
    def add_npc(npc)
        npcs << npc
        Message.register_listener(self, :core, npc)
    end
    def remove_npc(npc)
        Message.unregister_listener(self, :core, npc)
        npcs.delete(npc)
    end
end
