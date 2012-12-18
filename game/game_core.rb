require 'world/factories'
require 'game/tables'
require 'raws/db.rb'

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
        @db = ObjectDB.new(raw_group)

        WordParser.load('words/dict')

        # Create the world and breathe life into it
#        @world            = World.test_world_2
        @world            = WorldFactory.generate(5, 3)
        populate
    end

    def populate
        Log.debug("Populating world with NPCs and items")
        # We're mostly going to rely on the zones themselves to do the population, since the zones have knowledge of their keywords
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
    def add_player(username, character)
        characters[username] = character
        character.set_position(cached_positions[username] || @world.random_starting_location)
        Message.register_listener(self, :core, character)
    end
    def has_active_character?(username)
        characters.has_key?(username)
    end
    def get_character(username)
        characters[username]
    end
    def remove_player(username)
        cached_positions[username] = characters[username].position
        Message.unregister_listener(self, :core, character)
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
