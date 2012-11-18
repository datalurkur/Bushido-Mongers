require 'socket'

require 'net/socket_utils'
require 'net/irc_conduit'
require 'net/irc_client'

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
                    alter_client_info(socket) do |hash|
                        hash[:listen_thread] = spawn_listen_thread_for(socket)
                    end
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
        Log.debug("Terminating client socket")
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

    def alter_client_info(socket, info = {}, &block)
        @sockets_mutex.synchronize {
            @client_sockets[socket].merge!(info)
            (block.call(@client_sockets[socket]) if block_given?)
        }
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
            mutex = get_client_info(socket)[:mutex]
            begin
                Log.name_thread(thread_name)
                data_buffer = ""
                while(true)
                    lines = []
                    Log.debug("Buffering input from client", 8)
                    while lines.empty?
                        new_lines = buffer_socket_input(socket, mutex, data_buffer)
                        lines.concat(new_lines)
                    end
                    Log.debug("Processing #{lines.size} lines of input from client", 8)
                    lines.each { |line| process_client_message(socket, line) }
                end
            rescue Exception => e
                Log.debug(["Thread exited abnormally", e.message, e.backtrace])
            end
        end
    end

    def send_to_client(socket, message)
        # This really doesn't need to be in a begin / rescue block, but until we find this thread concurrency bug, I need all the logging I can get
        begin
            Log.debug("Packing message #{message.type} for client", 8)
            packed_data = pack_message(message)
            Log.debug("Fetching client mutex", 8)
            get_client_info(socket)[:mutex].synchronize {
                Log.debug("Message going out to socket", 8)
                #socket.puts(packed_data)
                begin
                    socket.write_nonblock(packed_data)
                rescue Exception => e
                    Log.debug(["Failed to write to client socket", e.message, e.backtrace])
                end
            }
            Log.debug("Message sent and mutex released", 8)
        rescue Exception => e
            Log.debug(["Failed to send data to client", e.message, e.backtrace])
        end
    end

    # Special callback for the IRC interface
    def new_irc_user(nick)
        IRCClient.new(@config[:listen_port], nick)
    end
end
