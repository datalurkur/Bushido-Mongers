require 'socket'
require './net/defaults'
require './net/irc_conduit'
require './net/irc_client'
require './util/message_buffer'
require './util/cfg_reader'

# Responsible for low-level socket IO, socket maintenance, and communication via IRC
# Listens for new connections in a separate thread
# Polls sockets for input on separate threads, for this reason, sockets should be modified and closed using the provided APIs
class Server
    def initialize(config_file)
        @running = false
        @config  = CFGReader.read(config_file)
        @config[:buffer_size] ||= DEFAULT_BUFFER_SIZE
        @config[:listen_port] ||= DEFAULT_LISTEN_PORT
        @config[:irc_port]    ||= DEFAULT_IRC_PORT
        @message_buffer = MessageBuffer.new
    end

    def start
        setup
        @running = true
    end

    def stop
        @running = false
        teardown
    end

    def is_running?; @running; end

    def setup
        start_listening_for_connections

        # Open the IRC Conduit if required
        if @config[:irc_enabled] == "1"
            IRCConduit.start(@config[:irc_server], @config[:irc_port], @config[:irc_nick], self)
        end
    end

    def start_listening_for_connections
        # Establish the listen socket
        # This is used not only be remotely connecting clients, but also by the IRC Clients

        @sockets_mutex = Mutex.new
        @client_sockets = {}

        @accept_socket = TCPServer.new(@config[:listen_port]) 
        @accept_thread = Thread.new do
            Log.name_thread("Accept")
            while(true)
                begin
                    # Accept the new connection
                    socket = @accept_socket.accept
                    client_thread = spawn_thread_for(socket)
                    set_client_info(socket, client_thread)
                rescue Exception => e
                    Log.debug(["Failed to accept connection",e.message,e.backtrace])
                end
            end
        end
    end

    def stop_listening_for_connections
        @accept_thread.kill
        @accept_socket.close
        @client_sockets.each_key do |k|
            @client_sockets[k].kill if @client_sockets[k].alive?
            k.close unless k.closed?
        end
        @client_sockets.clear
        @sockets_mutex = nil
    end

    def teardown
        stop_listening_for_connections
        if @config[:irc_enabled] == "1"
            IRCConduit.stop
        end
        @message_buffer.report
    end

    def set_client_info(socket,info)
        @sockets_mutex.synchronize { @client_sockets[socket] = info }
    end

    def terminate_client(socket)
        Log.debug("Terminating client socket")
        @sockets_mutex.synchronize do
            @client_sockets[socket].kill if @client_sockets[socket] && @client_sockets[socket].alive?
            @client_sockets.delete(socket)
        end
        socket.close unless socket.closed?
    end

    def spawn_thread_for(socket)
        sockaddr = socket.addr.last
        @threadcount           ||= {}
        @threadcount[sockaddr] ||= 0
        @threadcount[sockaddr]  += 1
        thread_name = "Cli #{@threadcount[sockaddr]}"
        Log.debug("Listening for client input from #{sockaddr}")
        Thread.new do
            Log.name_thread(thread_name)
            begin
                while(true)
                    begin
                        data = socket.read_nonblock(@config[:buffer_size])
                        raise(Errno::ECONNRESET) if data.empty?
                        messages = @message_buffer.unpack_messages(data)
                        messages.each do |message|
                            process_client_message(message, socket)
                        end
                    rescue Errno::EWOULDBLOCK,Errno::EAGAIN
                        IO.select([socket])
                        retry
                    rescue EOFError => e
                        raise(e)
                    rescue Exception => e
                        Log.error(["Processing error - #{e.message}", e.backtrace])
                    end
                end
            rescue Errno::ECONNRESET,EOFError,IOError
                Log.debug("Client disconnected")
                socket.close
            rescue Exception => e
                Log.error("Thread exited abnormally (#{e.class} : #{e.message})")
            end
            terminate_client(socket)
        end
    end

    def send_to_client(socket, message)
        begin
            #Log.debug("Packing message #{message.type} for client", 8)
            packed_data = @message_buffer.pack_message(message)
            socket.write_nonblock(packed_data)
            return true
        rescue Exception => e
            Log.debug(["Failed to send data to client", e.message, e.backtrace])
            terminate_client(socket)
            return false
        end
    end

    # Special callback for the IRC interface
    def new_irc_user(nick)
        IRCClient.new(@config[:listen_port], nick)
    end
end
