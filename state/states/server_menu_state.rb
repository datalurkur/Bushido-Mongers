require './state/state'
require './util/crypto'

class ServerMenuState < State
    def setup_exchanges
        @server_menu_exchange = define_exchange(:choose_from_list, {:field => :server_menu, :choices => server_menu_choices}) do |choice|
            case choice
            when :list_lobbies; begin_exchange(@list_lobbies)
            when :create_lobby; @entry_type = :create_lobby; begin_exchange(@join_lobby)
            when :join_lobby;   @entry_type = :join_lobby;   begin_exchange(@join_lobby)
            when :disconnect;   LoginState.new(@client)
            end
        end

        @list_lobbies = define_exchange(:server_query, {:query_method => :list_lobbies}) do |args|
            @client.send_to_client(Message.new(:list, {:field=>:available_lobbies, :items=>args[:lobbies]}))
            begin_exchange(@server_menu_exchange)
        end

        @join_lobby = define_exchange_chain([
            [:server_query, {:query_method => :list_lobbies}],
            [:choose_from_list, {:field => :lobby_name, :choices_from => :lobbies}],
            [:text_field,       {:field => :lobby_password}]
        ]) do
            enter_lobby(@entry_type)
        end
    end

    def make_current
        case @client.get(:server_menu_autocmd)
        when :join_lobby
            enter_lobby(:join_lobby)
        when :create_lobby
            enter_lobby(:create_lobby)
        else
            @client.send_to_server(Message.new(:get_motd))
        end
    end

    def server_menu_choices; [:list_lobbies, :join_lobby, :create_lobby, :disconnect]; end

    def enter_lobby(entry_type)
        password_hash = LameCrypto.hash_using_method(@client.get(:hash_method),@client.get(:password),@client.get(:server_hash))
        @client.unset(:password)
        @client.send_to_server(Message.new(entry_type,{:lobby_name=>@client.get(:lobby_name),:lobby_password=>password_hash}))
    end

    def from_server(message)
        case message.type
        when :motd
            pass_to_client(message)
            begin_exchange(@server_menu_exchange)
        when :join_success,
             :create_success
            pass_to_client(message)
            LobbyState.new(@client)
        when :join_fail,
             :create_fail
            pass_to_client(message)
            @entry_type = nil
            begin_exchange(@server_menu_exchange)
        when :admin_change
            if message.result != @client.get(:username)
                Log.debug("Something really funky is happening - we're getting a message that the admin has been set to #{message.result} (not this user) during the server menu state.  How the hell.")
            else
                pass_to_client(message)
            end
        else
            super(message)
        end
    end
end
