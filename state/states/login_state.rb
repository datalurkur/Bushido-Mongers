require 'state/state'
require 'state/states/lobby_state'
require 'state/states/server_menu_state'
require 'util/crypto'

class LoginState < State
    def initialize(client, method)
        super(client, method)

        @username_exchange = define_exchange(:text_field, {:field => :username}) do
            send_login_request
        end

        @password_exchange = define_exchange(:text_field, {:field => :password}) do
            send_auth_response
        end

        @client.get(:username) ? send_login_request : begin_exchange(@username_exchange)
    end

    def from_server(message)
        case message.type
        when :auth_request
            if @local_state == :login_request
                @client.set(:hash_method,message.hash_method)
                @client.set(:server_hash,message.server_hash)
                @client.get(:password) ? send_auth_response : begin_exchange(@password_exchange)
                return
            end
        when :login_reject, :auth_reject
            pass_to_client(message)
            begin_exchange(@username_exchange)
            return
        when :auth_accept
            pass_to_client(message)
            ServerMenuState.new(@client, :set)
            return
        end

        super(message)
    end

    def send_login_request
        @client.send_to_server(Message.new(:login_request, {:username=>@client.get(:username)}))
        @local_state = :login_request
    end

    def send_auth_response
        hash = LameCrypto.hash_using_method(@client.get(:hash_method),@client.get(:password),@client.get(:server_hash))
        @client.unset(:password)
        @client.set(:password_hash,hash)
        @client.send_to_server(Message.new(:auth_response, {:password_hash=>@client.get(:password_hash)}))
        @local_state = :auth_response
    end
end
