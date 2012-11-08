require 'socket'

require 'socket_utils'
require 'irc_conduit'
require 'irc_client'

# Responsible for low-level socket IO, socket maintenance, and communication via IRC
# Listens for new connections in a separate thread
# Polls sockets for input on separate threads, for this reason, sockets should be modified and closed using the provided APIs
class Server
    include SocketUtils

    def initialize(config={})
        @config  = config
        @running = false

        setup
    end

    def is_running?; @running; end

    def setup
        start_listening_for_connections

        # Open the IRC Conduit if required
        if @config[:irc_enabled]
            IRCConduit.start(@config[:irc_server], @config[:irc_port], @config[:irc_nick], self)
        end

        @running = true
    end

    def start_listening_for_connections
        # Establish the listen socket
        # This is used not only be remotely connecting clients, but also by the IRC Clients
        Log.debug("Listen port undefined, using default port #{DEFAULT_LISTEN_PORT}") unless @config[:listen_port]
        @config[:listen_port] ||= DEFAULT_LISTEN_PORT

        @sockets_mutex = Mutex.new
        @client_sockets = {}

        @accept_socket = TCPServer.new(@config[:listen_port]) 
        @accept_thread = Thread.new do
            Log.name_thread("accept_thread")
            while(true)
                begin
                    # Accept the new connection
                    socket = @accept_socket.accept
                    set_client_info(socket, {
                        :state         => :accepted,
                        :mutex         => Mutex.new
                    })
                    alter_client_info(socket, {:listen_thread => spawn_listen_thread_for(socket)})
                rescue Exception => e
                    Log.debug(["Failed to accept connection",e.message,e.backtrace])
                end
            end
        end
    end

    def stop_listening_for_connections
        @accept_thread.kill
        @accept_socket.close
        @sockets_mutex.synchronize do
            @client_sockets.each_key do |k|
                @client_sockets[k][:listen_thread].kill
                k.close
            end
            @client_sockets.clear
        end
    end

    def teardown
        stop_listening_for_connections
        IRCConduit.stop
        @running = false
    end

    def terminate_client(socket)
        @sockets_mutex.synchronize {
            @client_sockets[socket][:listen_thread].kill
            socket.close
            @client_sockets.delete(socket)
        }
    end

    def get_client_info(socket)
        info = nil
        @sockets_mutex.synchronize { info = @client_sockets[socket] }
        info
    end

    def alter_client_info(socket,info)
        @sockets_mutex.synchronize { @client_sockets[socket].merge!(info) }
    end

    def set_client_info(socket,info)
        @sockets_mutex.synchronize { @client_sockets[socket] = info }
    end

    def spawn_listen_thread_for(socket)
        sockaddr = socket.addr.last
        @threadcount           ||= {}
        @threadcount[sockaddr] ||= 0
        @threadcount[sockaddr]  += 1
        thread_name = "#{sockaddr} (#{@threadcount[sockaddr]})"
        Log.debug("Listening for client input from #{sockaddr}")
        Thread.new do
            Log.name_thread(thread_name)
            data_buffer = ""
            while(true)
                begin
                    lines = []
                    while lines.empty?
                        new_lines = buffer_socket_input(socket, get_client_info(socket)[:mutex], data_buffer)
                        lines.concat(new_lines)
                    end
                    lines.each { |line| process_client_message(socket, line) }
                rescue Exception => e
                    Log.debug(["Server failed to process input from socket",e.message,e.backtrace])
                end
            end
        end
    end

    def send_to_client(socket, message)
        packed_data = pack_message(message)
        get_client_info(socket)[:mutex].synchronize {
            socket.puts(packed_data)
        }
    end

    # Special callback for the IRC interface
    def new_irc_user(nick)
        IRCClient.new(@config[:listen_port], nick)
    end
end
