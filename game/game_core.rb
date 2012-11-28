require 'world/world'
require 'game/player'

class GameCore
    attr_reader :world

    def initialize(args={})
        @world            = World.test_world
        @players          = {}
        @positions        = {}
        @cached_positions = {}
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
