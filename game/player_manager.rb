require 'game/player'

module PlayerManager
    private
    def players
        @players ||= {}
    end

    def player_positions
        @player_position ||= {}
    end

    public
    def has_player?(player)
        players.has_key?(player)
    end

    def get_player(player)
        raise ArgumentError if players.has_key?(player)
        players[player]
    end

    def add_player(player, character, start_position)
        raise ArgumentError if players.has_key?(player)
        players[player]          = character
        player_positions[player] = start_position
    end

    def remove_player(player)
        player_positions.delete(player)
        players.delete(player)
    end

    def get_player_position(player)
        raise ArgumentError unless player_positions.has_key?(player)
        player_positions[player]
    end

    def set_player_position(player, position)
        raise ArgumentError unless player_positions.has_key?(player)
        player_positions[player] = position
    end

    def player_can_move?(player, direction, reason)
        old_room = get_player_position(player)
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
end
