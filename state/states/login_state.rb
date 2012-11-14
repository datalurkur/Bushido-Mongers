require 'state/state'
require 'state/states/lobby_state'
require 'state/states/server_menu_state'
require 'util/crypto'

class LoginState < State
    def initialize(client)
        super(client)

        define_exchange(:username, :text_field) do
            send_login_request
        end

        define_exchange(:password, :text_field) do
            send_auth_response

        end

        @client.send_to_client(Message.new(:notify, {:text => "Preparing to log in"}))
        @client.get(:username) ? send_login_request : begin_exchange(:name)
    end

    def from_server(message)
        case message.type
        when :login_reject
            if @local_state == :login_request
                # anjean ; fix this to not crash ; BAYUD
                raise "Login failed - #{message.reason}"
            end
        when :auth_request
            if @local_state == :login_request
                @client.set(:hash_method,message.hash_method)
                @client.set(:server_hash,message.server_hash)
                @client.get(:password) ? send_auth_response : begin_exchange(:password)
                return
            end
        when :auth_reject
            if @local_state == :auth_response
                raise "Login failed - #{message.reason}"
            end
        when :auth_accept
            if @local_state == :auth_response
                # Move to the Server Menu state
                @client.set_state(ServerMenuState.new(@client))
                return
            end
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
