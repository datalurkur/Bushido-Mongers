require 'world/world'
require 'game/player_manager'
require 'ai/npc_manager'

class GameCore
    attr_reader :world

    include NPCManager
    include PlayerManager

    def initialize(args={})
        @world            = World.test_world_2
        @cached_positions = {}

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

    def add_player(username, character)
        start_position = if @cached_positions[username]
            @cached_positions[username]
        else
            @world.random_starting_location
        end
        super(username, character, start_position)
    end

    def remove_player(username)
        @cached_positions[username] = get_player_position(username)
        super(username)
    end
end
