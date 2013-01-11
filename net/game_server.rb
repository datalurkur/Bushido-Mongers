require 'net/server'
require 'net/web_enabled_lobby'

# GameServer is responsible for handling client communications above the socket layer and delegating them where appropriate
# Handles logins and authentication
# Handles lobby creation, maintenance, and destruction
class GameServer < Server
    def initialize(config={})
        super(config)

        @user_mutex  = Mutex.new
        @user_info   = {}

        @lobby_mutex = Mutex.new
        @lobbies     = []

        @web_server  = HTTPServer.new(WEB_ROOT, HTTP_LISTEN_PORT)

        # Allow files at the root to be accessed
        @web_server.add_route(/\/#{@web_server.wildcard}$/i) do |args|
            @web_server.find_file(args.first)
        end
        @web_server.add_route(/\/$/) { @web_server.process_template("index.erb", binding) }
    end

    def start
        super()
        @web_server.start
    end

    def stop
        @web_server.stop
        super()
    end

    def get_socket_for_user(username)
        matching_sockets = nil
        @user_mutex.synchronize { matching_sockets = @user_info.keys.select { |s| @user_info[s][:username] == username } }
        if matching_sockets.size > 1
            Log.debug("WARNING - Multiple sockets found for user #{username}")
            nil
        elsif matching_sockets.size == 0
            Log.debug("WARNING - Socket not found for user #{username}")
            nil
        else
            matching_sockets.first
        end
    end

    def process_client_message(message, socket)
        case message.message_class
        when :login;       process_login_message(message, socket)
        when :server_menu; process_server_menu_message(message, socket)
        when :lobby,:game; process_lobby_message(message, socket)
        else
            Log.debug("Unhandled class of client message: #{message.message_class}")
        end
    end

    def process_server_menu_message(message, socket)
        @user_mutex.synchronize {
            if @user_info[socket][:state] != :server_menu
                debug("Invalid message - #{@user_info[socket][:username]} is not in the server menu")
                return
            end
        }
        case message.type
        when :get_motd
            send_to_client(socket, Message.new(:motd,{:text=>@config[:motd]}))
        when :list_lobbies
            lobbies = @lobby_mutex.synchronize {
                @lobbies.collect { |lobby| lobby.name }
            }
            send_to_client(socket, Message.new(:lobby_list,{:lobbies=>lobbies}))
        when :join_lobby
            lobby         = nil
            username      = nil
            password_hash = nil
            @user_mutex.synchronize {
                username      = @user_info[socket][:username]
                password_hash = message.lobby_password.xor(@user_info[socket][:server_hash])
            }
            @lobby_mutex.synchronize {
                lobby = @lobbies.find { |lobby| lobby.name == message.lobby_name }
            }
            if lobby.nil?
                send_to_client(socket, Message.new(:join_fail, {:reason => :lobby_does_not_exist}))
            elsif lobby.check_password(password_hash)
                @lobby_mutex.synchronize {
                    lobby.add_user(username)
                }
                @user_mutex.synchronize {
                    @user_info[socket][:lobby] = lobby
                    @user_info[socket][:state] = :lobby
                }
                send_to_client(socket, Message.new(:join_success))
            else
                send_to_client(socket, Message.new(:join_fail, {:reason => :incorrect_password}))
            end
        when :create_lobby
            password_hash = nil
            username      = nil
            @user_mutex.synchronize {
                password_hash = message.lobby_password.xor(@user_info[socket][:server_hash])
                username      = @user_info[socket][:username]
            }
            @lobby_mutex.synchronize {
                if @lobbies.find { |lobby| lobby.name == message.lobby_name }
                    send_to_client(socket, Message.new(:create_fail, {:reason => :lobby_exists}))
                else
                    lobby = WebEnabledLobby.new(message.lobby_name, password_hash, username, @web_server) do |user, message|
                        socket = get_socket_for_user(user)
                        send_to_client(socket, message) unless socket.nil?
                    end
                    @lobbies << lobby
                    @user_mutex.synchronize do
                        @user_info[socket][:lobby] = lobby
                        @user_info[socket][:state] = :lobby
                    end
                    send_to_client(socket, Message.new(:create_success))
                end
            }
        else
            Log.debug("Unhandled server menu message type #{message.type} received from client")
        end
    end

    def process_login_message(message, socket)
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
        when :auth_response
            competing_sockets = []
            username          = nil
            password_hash     = nil
            @user_mutex.synchronize {
                if @user_info[socket][:state] != :authenticating
                    Log.debug("Invalid authentication response from client in #{@user_info[socket][:state]} state")
                    return
                end

                username      = @user_info[socket][:username]
                password_hash = @user_info[socket][:server_hash].xor(message.password_hash || "")

                @user_info[socket][:password_hash] = password_hash
                competing_sockets = @user_info.keys.select { |k|
                    (@user_info[k][:username] == username) && @user_info[k].has_key?(:password_hash)
                }
            }
            if competing_sockets.size > 2
                Log.debug("Warning: Inconsistent user state for #{username}")
            end
            if competing_sockets.size > 1
                Log.debug("Username #{username} already active")
                # There are other sockets with this username, see if the password matches
                matching_passwords = []
                @user_mutex.synchronize {
                    matching_passwords = competing_sockets.select { |k|
                        (@user_info[k][:password_hash] == password_hash)
                    }
                }
                if matching_passwords.size == competing_sockets.size
                    # The passwords match, this must be a reconnecting user
                    # Close the other sockets
                    other_sockets = competing_sockets.reject { |k| k == socket }
                    other_sockets.each do |k|
                        lobby = nil
                        @user_mutex.synchronize {
                            lobby = @user_info[k][:lobby]
                            @user_info.delete(k)
                            terminate_client(k)
                        }
                        lobby.remove_user(username) if lobby
                    end
                else
                    @user_mutex.synchronize {
                        @user_info[socket].delete(:password_hash)
                    }
                    send_to_client(socket, Message.new(:auth_reject, {:reason => :incorrect_password}))
                    return
                end
            end
            @user_mutex.synchronize { @user_info[socket][:state] = :server_menu }
            send_to_client(socket, Message.new(:auth_accept))
        else
            Log.debug("Unhandled login message type #{message.type} received from client")
        end
    end

    def process_lobby_message(message, socket)
        lobby      = nil
        user_state = nil
        username   = nil
        @user_mutex.synchronize {
            user_state = @user_info[socket][:state]
            username   = @user_info[socket][:username]
            lobby      = @user_info[socket][:lobby]
        }
        if user_state != :lobby || lobby.nil?
            Log.debug("Invalid lobby message received from client")
            return
        end
        lobby.process_message(message, username)
    end
end
