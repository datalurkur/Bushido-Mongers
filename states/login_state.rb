require 'state'
require 'states/server_menu_state'
require 'crypto_utils'

class LoginState < State
    def initialize(client)
        super(client)
        @client.send_to_client(Message.new(:notify, {:text => "Preparing to log in"}))
        Log.debug(client.get_internal_state.inspect)
        @client.get(:username) ? send_login_request : query_name
    end

    def from_client(message)
        case message.type
        when :response
            if @local_state == :query_name
                @client.set(:username,message.value)
                send_login_request
                return
            elsif @local_state == :query_password
                #hash = LameCrypto.hash_using_method(@client.get(:hash_method),message.value,@client.get(:server_hash))
                #@client.set(:password_hash,hash)
                @client.set(:password,message.value)
                send_auth_response
                return
            end
        end

        super(message)
    end

    def from_server(message)
        case message.type
        when :login_reject
            if @local_state == :login_request
                raise "Login failed - #{message.reason}"
            end
        when :auth_request
            if @local_state == :login_request
                @client.set(:hash_method,message.hash_method)
                @client.set(:server_hash,message.server_hash)
                @client.get(:password) ? send_auth_response : query_password
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

    def query_name
        @client.send_to_client(Message.new(:query, {:field=>:username}))
        @local_state = :query_name
    end

    def query_password
        @client.send_to_client(Message.new(:query, {:field=>:password}))
        @local_state = :query_password
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
