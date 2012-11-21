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
        @positions[username]
    end

    def remove_player(username)
        @cached_positions[username] = @positions[username]
        @players.delete(username)
        @positions.delete(username)
    end
end
