require './state/state'
require './state/states/server_menu_state'
require './state/states/playing_state'
require './state/states/create_character_state'

class LobbyState < State
    def setup_exchanges
        @select_character_exchange = define_exchange_chain([
            [:server_query,     {:query_method => :list_characters}],
            [:choose_from_list, {:field => :character, :choices_from => :characters}],
        ]) do |choice|
            @client.send_to_server(Message.new(:select_character, {:character_name => choice}))
        end

        @lobby_menu_exchange = define_exchange(:choose_from_list, {:field => :lobby_menu, :choices => lobby_menu_choices}) do |choice|
            case choice
            when :get_game_params
                @client.send_to_server(Message.new(:get_game_params))
            when :generate_game
                @client.send_to_server(Message.new(:generate_game))
            when :create_character
                CreateCharacterState.new(@client, :push)
            when :select_character
                begin_exchange(@select_character_exchange)
            when :start_game
                @client.send_to_server(Message.new(:start_game))
            when :leave_lobby
                @client.send_to_server(Message.new(:leave_lobby))
                @client.unset(:lobby_name)
                @client.unset(:lobby_password)
                @client.unset(:server_menu_autocmd)
                ServerMenuState.new(@client)
            end
        end
    end

    def make_current
        begin_exchange(@lobby_menu_exchange)
    end

    # FIXME - This menu needs to be refined and broken up into categories (game administration, character selection, etc)
    def lobby_menu_choices; [:get_game_params, :generate_game, :create_character, :select_character, :start_game, :leave_lobby]; end

    def from_server(message)
        case message.type
        when :admin_change,
             :user_joins
            pass_to_client(message)
        when :game_params
            @client.send_to_client(Message.new(:list, {:field=>:game_parameters, :items=>message.params}))
            begin_exchange(@lobby_menu_exchange)
        when :generation_success,
             :generation_fail,
             :start_success,
             :start_fail,
             :character_ready,
             :character_not_ready,
             :no_characters
            pass_to_client(message)
            begin_exchange(@lobby_menu_exchange)
        when :begin_playing
            PlayingState.new(@client)
            pass_to_client(message)
        else
            super(message)
        end
    end
end
