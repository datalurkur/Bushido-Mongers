require 'state/state'
require 'state/states/playing_state'

class LobbyState < State
    def initialize(client, method)
        super(client, method)
        @client.send_to_client(Message.new(:notify, {:text=>"You have entered the lobby"}))

        define_exchange_chain([
            [:characters,       :server_query,     {:query_method => :list_characters}],
            [:character,        :choose_from_list, {:choices_from => :characters}],
        ]) do |choice|
            @client.send_to_server(Message.new(:select_character, {:character_name => @client.get(:character)}))
        end

        define_exchange(:menu_choice, :choose_from_list, {:choices => menu_choices}) do |choice|
            case choice
            when :get_game_params
                @client.send_to_server(Message.new(:get_game_params))
            when :generate_game
                @client.send_to_server(Message.new(:generate_game))
            when :create_character
                raise "This really needs its own menu, even apart from the character selection sub-menu that already needs to exist (and doesn't)"
            when :select_character
                begin_exchange(:characters)
            when :start_game
                @client.send_to_server(Message.new(:start_game))
            end
        end

        begin_exchange(:menu_choice)
    end

    # FIXME - This menu needs to be refined and broken up into categories (game administration, player selection, etc)
    def menu_choices; [:get_game_params, :generate_game, :create_character, :select_character, :start_game]; end

    def from_server(message)
        case message.type
        when :admin_change
            @client.send_to_client(Message.new(:notify, {:text=>"#{message.admin} has assumed the role of admin"}))
        when :game_params
            @client.send_to_client(Message.new(:list, {:title=>"Game Parameters", :items=>message.params}))
            begin_exchange(:menu_choice)
            return
        when :generation_success
            @client.send_to_client(Message.new(:notify, {:text=>"World has been generated"}))
            begin_exchange(:menu_choice)
            return
        when :generation_fail
            @client.send_to_client(Message.new(:notify, {:text=>"World failed to generate, #{message.reason}"}))
            begin_exchange(:menu_choice)
            return
        when :start_success
            @client.send_to_client(Message.new(:notify, {:text=>"Game has started"}))
            begin_exchange(:menu_choice)
            return
        when :start_fail
            @client.send_to_client(Message.new(:notify, {:text=>"Game failed to start, #{message.reason}"}))
            begin_exchange(:menu_choice)
            return
        when :user_joins
            @client.send_to_client(Message.new(:notify, {:text=>"#{message.username} has joined the lobby"}))
            return
        when :character_ready
            @client.send_to_client(Message.new(:notify, {:text=>"Character ready"}))
            begin_exchange(:menu_choice)
            return
        when :character_not_ready
            @client.send_to_client(Message.new(:notify, {:text=>"Character not ready - #{message.reason}"}))
            begin_exchange(:menu_choice)
            return
        when :begin_playing
            Log.debug("Entering PlayingState")
            @client.set_state(PlayingState.new(@client))
            return
        end

        super(message)
    end
end
