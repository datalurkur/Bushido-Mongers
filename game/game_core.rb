require 'world/world'
require 'game/player'

class GameCore
    attr_reader :world

    def initialize(args={})
        @world            = World.test_world_2
        @npcs             = []
        @players          = {}
        @positions        = {}
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
        @players[username]   = character
        @positions[username] = if @cached_positions[username]
            @cached_positions[username]
        else
            @world.random_starting_location
        end
    end

    def has_player?(username)
        @players.has_key?(username)
    end

    def get_player(username)
        @players[username]
    end

    def get_player_position(username)
        coords = @positions[username]
        room   = @world.get_zone(coords)
        raise "Player is not in a room!" unless Room === room
        room
    end

    def set_player_position(username, room)
        raise "Player is not in a room!" unless Room === room
        @positions[username] = room.get_full_coordinates
    end

    def player_can_move?(username, direction, reason)
        old_room = get_player_position(username)
        if !(old_room.connected_to?(direction))
            reason = :no_path
            false
        else
            return true
        end
    end

    def move_player(username, direction)
        old_room = get_player_position(username)
        new_room = old_room.connected_leaf(direction)

        Log.debug("Moving #{username} from #{old_room.name} to #{new_room.name}")
        set_player_position(username, new_room)
    end

    def remove_player(username)
        @cached_positions[username] = @positions[username]
        @players.delete(username)
        @positions.delete(username)
    end
end
