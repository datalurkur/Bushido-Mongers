require 'world/world'

class GameCore
    attr_reader :world

    def initialize(args={})
        @world            = World.test_world_2

        # TODO - Set this to something much higher once we're out of debug
        @tick_rate        = args[:tick_rate] || (5)
        @ticking          = false
        @ticking_mutex    = Mutex.new
    end

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

    def characters;       @characters ||= {};       end

    def cached_positions; @cached_positions ||= {}; end

    def add_player(username, character)
        characters[username] = character
        character.set_position(cached_positions[username] || @world.random_starting_location)
    end

    def has_active_character?(username)
        characters.has_key?(username)
    end

    def get_character(username)
        characters[username]
    end

    def remove_player(username)
        cached_positions[username] = characters[username].position
        characters.delete(username)
    end

    def npcs
        @npcs ||= []
    end

    def add_npc(npc)
        @npcs << npc
        Message.register_listener(self, :core, npc)
    end

    def remove_npc(npc)
        Message.unregister_listener(self, :core, npc)
        @npcs.delete(npc)
    end
end
