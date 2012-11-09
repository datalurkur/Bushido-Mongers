require 'server'

# GameServer is responsible for handling client communications above the socket layer and delegating them where appropriate
# Handles logins and authentication
# Handles lobby creation, maintenance, and destruction
class GameServer < Server
    def initialize(config={})
        super(config)

        @user_mutex = Mutex.new
        @user_info  = {}

        @lobby_info = {}
    end

    def process_client_message(socket,message)
        case message.message_class
        when :protocol; process_protocol_message(socket,message)
        else
            debug("Unhandled class of client message: #{message.message_class}")
        end
    end

    def process_protocol_message(socket,message)
        case message.type
        when :login_request
            server_hash = Digest::MD5.new.to_s
            @user_mutex.synchronize {
                @user_info[socket] ||= {}
                @user_info[socket][:username]    = message.username
                @user_info[socket][:server_hash] = server_hash
                @user_info[socket][:state]       = :authenticating
            }
            send_to_client(socket, Message.new(:auth_request,{
                :hash_method => :md5_and_xor,
                :server_hash => server_hash
            }))
            return
        when :auth_response
            competing_sockets = []
            @user_mutex.synchronize {
                if @user_info[socket][:state] != :authenticating
                    debug("Invalid authentication response from client in #{@user_info[socket][:state]} state")
                    return
                end

                username      = @user_info[socket][:username]
                password_hash = @user_info[socket][:server_hash].xor(message.password_hash)

                @user_info[socket][:password_hash] = password_hash
                competing_sockets = @user_info.keys.select { |k|
                    (@user_info[k][:username] == username)
                }
                if competing_sockets.size > 1
                    Log.debug("Username #{username} already active")
                    # There are other sockets with this username, see if the password match
                    matching_passwords = @user_info.keys.select { |k|
                        (@user_info[k][:password_hash] == password_hash) || @user_info[k][:password_hash].nil?
                    }
                    if matching_passwords.size == competing_sockets.size
                        # The passwords match, this must be a reconnecting user
                        # Close the other sockets
                        other_sockets = competing_sockets.reject { |k| k == socket }
                        other_sockets.each { |k| @user_info.delete(k); terminate_client(k) }
                    else
                        send_to_client(socket, Message.new(:auth_reject,{:reason => "Incorrect password"}))
                        return
                    end
                end
                send_to_client(socket, Message.new(:auth_accept))
                return
            }
        else
            debug("Unhandled message type #{message.type} received from client")
            return
        end
    end
end
