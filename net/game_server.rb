require './net/server'
require './net/web_enabled_lobby'
require './http/web_renderer'
require './http/web_socket_client'

# GameServer is responsible for handling client communications above the socket layer and delegating them where appropriate
# Handles logins and authentication
# Handles lobby creation, maintenance, and destruction
class GameServer < Server
    include WebRenderer

    def initialize(config={})
        super(config)
        @config[:web_port] = (@config[:web_port] || DEFAULT_HTTP_PORT).to_i
        @config[:web_root] =  @config[:web_root] || DEFAULT_WEB_ROOT

        @user_mutex  = Mutex.new
        @user_info   = {}

        @lobby_mutex = Mutex.new
        @lobbies     = []

        @web_server  = HTTPServer.new(@config[:web_root], @config[:web_port])
        @web_server.add_route(/^\/$/) do
            get_template(File.join(@web_server.web_root, "index.haml"), {:game_server => self})
        end
        # Allow files at the root to be accessed
        @web_server.add_route(/^\/#{wildcard}$/i) do |args|
            get_file(File.join(@web_server.web_root, args.first))
        end
        @web_server.add_route(/^\/console$/) do
            get_template(File.join(@web_server.web_root, "console.haml"))
        end
        @web_server.add_route(/^\/console_websocket$/) do |socket|
            Log.debug("Attempting to create WebSocketClient")
            if TCPSocket === socket
                WebSocketClient.new(socket, @config[:listen_port])
            else
                Log.error("Can't create WebSocketClient with #{socket.class}")
            end
        end
    end

    def each_lobby(&block)
        @lobby_mutex.synchronize do
            @lobbies.each do |lobby|
                yield(lobby)
            end
        end
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
        @user_mutex.synchronize do
            matching_sockets = @user_info.keys.select do |s|
                (@user_info[s][:username] == username) && @user_info[s].has_key?(:password_hash)
            end
        end
        if matching_sockets.size > 1
            Log.warning(["Multiple sockets found for user #{username}", @user_info])
            nil
        elsif matching_sockets.size == 0
            Log.warning("Socket not found for user #{username}")
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
        case message.type
        when :get_motd
            send_to_client(socket, Message.new(:motd,{:text=>@config[:motd]}))
        when :list_lobbies
            lobbies = @lobby_mutex.synchronize {
                @lobbies.collect { |lobby| lobby.name }
            }
            send_to_client(socket, Message.new(:lobby_list,{:lobbies=>lobbies}))
        when :join_lobby
            username      = nil
            user_state    = nil
            password_hash = nil
            @user_mutex.synchronize {
                username      = @user_info[socket][:username]
                user_state    = @user_info[socket][:state]
                password_hash = message.lobby_password.xor(@user_info[socket][:server_hash])
            }
            if user_state != :server_menu
                send_to_client(socket, Message.new(:join_fail, {:reason => :not_in_server_menu}))
            end

            lobby = nil
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
        when :leave_lobby
            username   = nil
            user_state = nil
            lobby      = nil
            @user_mutex.synchronize {
                username   = @user_info[socket][:username]
                user_state = @user_info[socket][:state]
                lobby      = @user_info[socket][:lobby]
            }
            if user_state != :lobby || lobby.nil?
                Log.error("User #{username} is not in a lobby")
            else
                lobby.remove_user(username)
                @user_mutex.synchronize {
                    @user_info[socket][:state] = :server_menu
                    @user_info[socket].delete(:lobby)
                }
            end
        when :create_lobby
            password_hash = nil
            username      = nil
            user_state    = nil
            @user_mutex.synchronize {
                password_hash = message.lobby_password.xor(@user_info[socket][:server_hash])
                username      = @user_info[socket][:username]
                user_state    = @user_info[socket][:state]
            }
            @lobby_mutex.synchronize {
                if @lobbies.find { |lobby| lobby.name == message.lobby_name }
                    send_to_client(socket, Message.new(:create_fail, {:reason => :lobby_exists}))
                elsif user_state != :server_menu
                    send_to_client(socket, Message.new(:join_fail, {:reason => :not_in_server_menu}))
                else
                    lobby = WebEnabledLobby.new(message.lobby_name, password_hash, username, @web_server) do |user, message|
                        socket = get_socket_for_user(user)
                        send_to_client(socket, message) unless socket.nil?
                    end
                    @lobbies << lobby
                    @user_mutex.synchronize {
                        @user_info[socket][:lobby] = lobby
                        @user_info[socket][:state] = :lobby
                    }
                    send_to_client(socket, Message.new(:create_success))
                end
            }
        else
            Log.warning("Unhandled server menu message type #{message.type} received from client")
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
            client_state = @user_mutex.synchronize { @user_info[socket][:state] }
            if client_state != :authenticating
                Log.debug("Invalid authentication response from client in #{client_state} state")
                return
            end

            competing_sockets = []
            username          = nil
            password_hash     = nil
            @user_mutex.synchronize do
                username      = @user_info[socket][:username]
                password_hash = @user_info[socket][:server_hash].xor(message.password_hash || "")

                @user_info[socket][:password_hash] = password_hash
                competing_sockets = @user_info.keys.select do |k|
                    next if k == socket
                    (@user_info[k][:username] == username) && @user_info[k].has_key?(:password_hash)
                end
            end
            if competing_sockets.size >= 2
                Log.debug("Warning: Inconsistent user state for #{username}")
            end
            if competing_sockets.size == 1
                Log.debug("Username #{username} already active")
                # There are other sockets with this username, see if the password matches
                matching_socket = nil
                @user_mutex.synchronize do
                    matching_socket = @user_info[competing_sockets.first]
                end

                if matching_socket[:password_hash] == password_hash
                    Log.debug("Password match, rejecting other socket")
                    @user_mutex.synchronize do
                        @user_info.delete(competing_sockets.first)
                    end
                    matching_socket[:lobby].remove_user(matching_socket[:username]) unless matching_socket[:lobby].nil?
                    terminate_client(competing_sockets.first)
                else
                    @user_mutex.synchronize do
                        @user_info[socket].delete(:password_hash)
                    end
                    send_to_client(socket, Message.new(:auth_reject, {:reason => :incorrect_password}))
                    return
                end
            end
            @user_mutex.synchronize do
                @user_info[socket][:state] = :server_menu
            end
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
