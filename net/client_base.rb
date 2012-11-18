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

    def initialize(ip,port)
        setup(ip,port)
    end

    def setup(ip,port)
        @socket = TCPSocket.new(ip,port)
        start_processing_server_messages
        start_processing_client_messages
    end

    def teardown
        stop_processing_client_messages
        stop_processing_server_messages
        @socket.close
    end

    def send_to_server(message)
        # This really doesn't need to be in a begin / rescue block, but until we find this thread concurrency bug, I need all the logging I can get
        begin
            Log.debug("Packing message #{message.type} for server", 8)
            packed_data = pack_message(message)
            Log.debug("Fetching socket mutex", 8)
            @socket_mutex.synchronize {
                Log.debug("Message going out to socket", 8)
                #@socket.puts(packed_data)
                begin
                    @socket.write_nonblock(packed_data)
                rescue Exception => e
                    Log.debug(["Failed to write to server socket", e.message, e.backtrace])
                end
            }
            Log.debug("Message sent and mutex released", 8)
        rescue Exception => e
            Log.debug(["Failed to send data to server", e.message, e.backtrace])
        end
    end

    def start_processing_server_messages
        @socket_mutex          = Mutex.new
        @server_mutex          = Mutex.new
        @server_message_buffer = []
        @server_listen_thread  = Thread.new do
            begin
                Log.name_thread("server_polling")
                data_buffer = ""
                while(true)
                    lines = []
                    Log.debug("Buffering input from server", 8)
                    while lines.empty?
                        new_lines = buffer_socket_input(@socket, @socket_mutex, data_buffer)
                        lines.concat(new_lines)
                    end
                    Log.debug("Received #{lines.size} lines of input from server", 8)
                    @server_mutex.synchronize { @server_message_buffer.concat(lines) }
                end
            rescue Errno::ECONNRESET
                # FIXME - We need to handle disconnects gracefully (ie bounce back to the login menu rather than dying horribly)
                raise Errno::ECONNRESET
            rescue Exception => e
                Log.debug(["Thread exited abnormally",e.message,e.backtrace])
            end
        end
    end

    def stop_processing_server_messages
        @server_listen_thread.kill
        @socket_mutex = nil
    end

    def start_processing_client_messages
        Log.debug("Polling for client messages")
        @client_mutex          = Mutex.new
        @client_message_buffer = []
        @client_listen_thread  = Thread.new do
            begin
                Log.name_thread("client_polling")
                while(true)
                    input = get_from_client
                    Log.debug("Received client message #{input.type}")
                    @client_mutex.synchronize { @client_message_buffer << input }
                end
            rescue Exception => e
                Log.debug(["Thread exited abnormally",e.message,e.backtrace])
            end
        end
    end

    def stop_processing_client_messages
        @client_listen_thread.kill
        @client_mutex = nil
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
