require 'socket'

require 'net/socket_utils'

require 'util/log'

# ClientBase provides a low-level interface to server and client communications
# In this case, the server is the actual server, and the "client" is whatever object is providing input from the user (this might be the command line or the IRCConduit, for example, hence the distinction)
# All of the interesting functionality happens in the subclass, this class serves only to facilitate communication
# Server IO is asynchronous
# Client IO is asynchronous
class ClientBase
    include SocketUtils

    def initialize
        @setup = false
    end

    def start
        setup
        @setup = true
    end

    def stop
        @setup = false
        teardown
    end

    def setup
        @client_message_buffer = []
        @client_mutex          = Mutex.new
        start_processing_client_messages

        @server_message_buffer = []
        @server_mutex          = Mutex.new
    end

    def connect(ip, port)
        raise "Can't attempt to connect until client has started" unless @setup
        @socket                = TCPSocket.new(ip,port)
        @socket_mutex          = Mutex.new
        start_processing_server_messages
    end

    def disconnect
        if @socket
            stop_processing_server_messages
            @socket.close
            @socket       = nil
            @socket_mutex = nil
        end
    end

    def teardown
        disconnect
        stop_processing_client_messages
    end

    def send_to_server(message)
        if @socket.nil?
            Log.error("No connection")
            return
        end

        # This really doesn't need to be in a begin / rescue block, but until we find this thread concurrency bug, I need all the logging I can get
        begin
            Log.debug("Packing message #{message.type} for server", 8)
            packed_data = pack_message(message)
            @socket_mutex.synchronize {
                begin
                    @socket.write_nonblock(packed_data)
                rescue Exception => e
                    Log.error(["Failed to write to server socket", e.message, e.backtrace])
                end
            }
        rescue Exception => e
            Log.error(["Failed to send data to server", e.message, e.backtrace])
        end
    end

    def start_processing_server_messages
        @server_listen_thread  = Thread.new do
            begin
                Log.name_thread("Comm")
                data_buffer = ""
                while(true)
                    messages = []
                    while messages.empty?
                        new_messages = buffer_socket_input(@socket, @socket_mutex, data_buffer)
                        new_messages.reject! do |message|
                            if message.type == :heartbeat
                                Log.debug("Heartbeat", 8)
                                send_to_server(Message.new(:heartbeat))
                            else
                                false
                            end
                        end
                        messages.concat(new_messages)
                    end
                
                    @server_mutex.synchronize { @server_message_buffer.concat(messages) }
                end
            rescue Errno::ECONNRESET
                # Pass a fake server message informing the client that the connection was reset
                reset_message = Message.new(:connection_reset)
                @server_mutex.synchronize { @server_message_buffer << reset_message }
            rescue Exception => e
                Log.error(["Thread exited abnormally",e.message,e.backtrace])
            end
        end
    end

    def stop_processing_server_messages
        @server_listen_thread.kill
    end

    def start_processing_client_messages
        Log.debug("Polling for client messages", 8)
        @client_listen_thread  = Thread.new do
            begin
                Log.name_thread("I/O")
                while(true)
                    if @setup && input = get_from_client
                        raise RuntimeError, "Received non-message #{input.inspect} from client!" unless Message === input
                        Log.debug("Received client message #{input.type}", 8)
                        @client_mutex.synchronize { @client_message_buffer << input }
                    end
                end
            rescue Exception => e
                Log.error(["Thread exited abnormally",e.message,e.backtrace])
            end
        end
    end

    def stop_processing_client_messages
        @client_listen_thread.kill
    end

    def get_client_messages
        ret = []
        @client_mutex.synchronize {
            ret = @client_message_buffer
            @client_message_buffer = []
        }
        ret
    end

    def get_server_messages
        ret = []
        @server_mutex.synchronize {
            ret = @server_message_buffer
            @server_message_buffer = []
        }
        ret
    end
end
