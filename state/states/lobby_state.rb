require 'state/state'
require 'state/states/playing_state'

class LobbyState < State
    def initialize(client, method)
        super(client, method)

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
                raise "This really needs its own menu, even apart from the character selection sub-menu that already needs to exist (and doesn't)"
            when :select_character
                begin_exchange(@select_character_exchange)
            when :start_game
                @client.send_to_server(Message.new(:start_game))
            end
        end

        begin_exchange(@lobby_menu_exchange)
    end

    # FIXME - This menu needs to be refined and broken up into categories (game administration, player selection, etc)
    def lobby_menu_choices; [:get_game_params, :generate_game, :create_character, :select_character, :start_game]; end

    def from_server(message)
        case message.type
        when :admin_change,
             :user_joins
            pass_to_client(message)
        when :game_params
            @client.send_to_client(Message.new(:list, {:title=>"Game Parameters", :items=>message.params}))
            begin_exchange(@lobby_menu_exchange)
            return
        when :generation_success,
             :generation_fail,
             :start_success,
             :start_fail,
             :character_ready,
             :character_not_ready
            pass_to_client(message)
            begin_exchange(@lobby_menu_exchange)
            return
        when :begin_playing
            pass_to_client(message)
            @client.set_state(PlayingState.new(@client))
            return
        end

        super(message)
    end
end
