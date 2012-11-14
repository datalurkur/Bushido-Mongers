require 'state/state'
require 'util/crypto'

class ServerMenuState < State
    def initialize(client)
        super(client)

        define_exchange(:menu_choice, :choose_from_list, {:choices => menu_choices}) do |choice|
            case choice
            when :list_lobbies; @client.send_to_server(Message.new(:list_lobbies))
            when :create_lobby; @entry_type = :create_lobby; begin_exchange(:lobby_name)
            when :join_lobby;   @entry_type = :join_lobby;   begin_exchange(:lobby_name)
            when :disconnect;   @client.set_state(LoginState.new(@client))
            end
        end

        define_exchange_chain([
            [:lobby_name,     :text_field],
            [:lobby_password, :text_field]
        ]) do
            password_hash = LameCrypto.hash_using_method(@client.get(:hash_method),@client.get(:password),@client.get(:server_hash))
            @client.unset(:password)
            @client.send_to_server(Message.new(@entry_type,{:lobby_name=>@client.get(:lobby_name),:lobby_password=>password_hash}))
        end

        @client.send_to_client(Message.new(:notify, {:text=>"You have connected to the server as #{@client.get(:name)}"}))
        @client.send_to_server(Message.new(:get_motd))
    end

    def menu_choices; [:list_lobbies, :join_lobby, :create_lobby, :disconnect]; end

    def from_server(message)
        case message.type
        when :motd
            @client.send_to_client(Message.new(:notify, {:text=>message.motd}))
            begin_exchange(:menu_choice)
            return
        when :lobby_list
            @client.send_to_client(Message.new(:list, {:title=>"Available Game Lobbies", :items=>message.lobbies}))
            begin_exchange(:menu_choice)
            return
        when :join_success
            @client.send_to_client(Message.new(:notify, {:text=>"Joined #{@client.get(:lobby_name)}"}))
            @client.set_state(LobbyState.new(@client))
            return
        when :join_fail
            @client.send_to_client(Message.new(:notify, {:text=>"Failed to join lobby: #{message.reason}"}))
            @entry_type = nil
            return
        when :create_success
            @client.send_to_client(Message.new(:notify, {:text=>"#{@client.get(:lobby_name)} created"}))
            @client.set_state(LobbyState.new(@client))
            return
        when :create_fail
            @client.send_to_client(Message.new(:notify, {:text=>"Failed to create lobby: #{message.reason}"}))
            @entry_type = nil
            return
        end

        super(message)
    end
end
