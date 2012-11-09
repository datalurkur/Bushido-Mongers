require 'state'
require 'crypto_utils'

class ServerMenuState < State
    def initialize(client)
        super(client)
        @client.send_to_client(Message.new(:notify, {:text=>"You have connected to the server as #{@client.get(:name)}"}))
        @client.send_to_server(Message.new(:get_motd))
    end

    def menu_choices; [
        :list_lobbies,
        :join_lobby,
        :create_lobby,
        :disconnect
    ]; end

    def display_menu
        @client.send_to_client(Message.new(:choose, {:field=>:server_menu,:choices=>menu_choices}))
    end
        
    def from_client(message)
        case message.type
        when :choice
            case message.choice
            when :list_lobbies
                @client.send_to_server(Message.new(:list_lobbies))
                return
            when :create_lobby
                @local_state = :create_name
                @client.send_to_client(Message.new(:query,{:field=>:lobby_name}))
                return
            when :join_lobby
                @local_state = :join_name
                @client.send_to_client(Message.new(:query,{:field=>:lobby_name}))
                return
            when :disconnect
                # anjean; eventually, LoginState will be replaced here with ConnectState
                @client.set_state(LoginState.new(@client))
                return
            end
        when :response
            case @local_state
            when :join_name
                @local_state = :join_password
                @client.set(:lobby_name,message.value)
                @client.send_to_client(Message.new(:query,{:field=>:lobby_password}))
                return
            when :join_password
                @local_state = :joining_lobby
                hashed_password = LameCrypto.hash_using_method(@client.get(:hash_method),message.value,@client.get(:server_hash))
                @client.send_to_server(Message.new(:join_lobby,{:lobby_name=>@client.get(:lobby_name),:lobby_password=>hashed_password}))
                return
            when :create_name
                @local_state = :create_password
                @client.set(:lobby_name,message.value)
                @client.send_to_client(Message.new(:query,{:field=>:lobby_password}))
                return
            when :create_password
                @local_state = :creating_lobby
                hashed_password = LameCrypto.hash_using_method(@client.get(:hash_method),message.value,@client.get(:server_hash))
                @client.send_to_server(Message.new(:create_lobby,{:lobby_name=>@client.get(:lobby_name),:lobby_password=>hashed_password}))
                return
            end
        when :invalid_choice
            display_menu
            return
        end

        super(message)
    end

    def from_server(message)
        case message.type
        when :motd
            @client.send_to_client(Message.new(:notify, {:text=>message.motd}))
            display_menu
            return
        when :lobby_list
            @client.send_to_client(Message.new(:list, {:title=>"Available Game Lobbies", :items=>message.lobbies}))
            display_menu
            return
        when :join_success
            @client.send_to_client(Message.new(:notify, {:text=>"Joined #{@client.get(:lobby_name)}"}))
            # anjean; fixme - switch to lobby state
            return
        when :join_fail
            @client.send_to_client(Message.new(:notify, {:text=>"Failed to join lobby: #{message.reason}"}))
            @local_state = nil
            return
        when :create_success
            @client.send_to_client(Message.new(:notify, {:text=>"#{@client.get(:lobby_name)} created"}))
            # anjean; fixme - switch to lobby state
            return
        when :create_fail
            @client.send_to_client(Message.new(:notify, {:text=>"Failed to create lobby: #{message.reason}"}))
            @local_state = nil
            return
        end

        super(message)
    end
end
