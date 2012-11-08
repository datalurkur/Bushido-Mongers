require 'state'
require 'states/server_menu_state'
require 'crypto_utils'

class LoginState < State
    def initialize(client)
        super(client)
        @client.send_to_client(Message.new(:notify, {:text => "Preparing to log in"}))
        @client.get(:name) ? send_login_request : query_name
    end

    def from_client(message)
        case message.type
        when :response
            if @local_state == :query_name
                @client.set(:name,message.value)
                send_login_request
                return
            elsif @local_state == :query_password
                hash = hash_password(message.value)
                @client.set(:password_hash,hash)
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
                query_password
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

    def hash_password(password)
        case @client.get(:hash_method)
        when :md5_and_xor
            LameCrypto.md5_and_xor(password, @client.get(:server_hash))
        else
            raise "Unrecognized hashing method #{@client.get(:hash_method)} requested by server"
        end
    end

    def query_name
        @client.send_to_client(Message.new(:query, {:field=>:name}))
        @local_state = :query_name
    end

    def query_password
        @client.send_to_client(Message.new(:query, {:field=>:password}))
        @local_state = :query_password
    end

    def send_login_request
        @client.send_to_server(Message.new(:login_request, {:username=>@client.get(:name)}))
        @local_state = :login_request
    end

    def send_auth_response
        @client.send_to_server(Message.new(:auth_response, {:password_hash=>@client.get(:password_hash)}))
        @local_state = :auth_response
    end
end
