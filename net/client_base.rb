require 'socket'
require './util/message_buffer'
require './util/cfg_reader'

# ClientBase provides a low-level interface to server and client communications
# In this case, the server is the actual server, and the "client" is whatever object is providing input from the user (this might be the command line or the IRCConduit, for example, hence the distinction)
# All of the interesting functionality happens in the subclass, this class serves only to facilitate communication
# Server IO is asynchronous
# Client IO is asynchronous
class ClientBase
    def initialize
        @setup  = false
        @config = {}
        @config[:buffer_size] = (CFGReader.get_param("net", :buffer_size) || DEFAULT_BUFFER_SIZE).to_i
        @message_buffer = MessageBuffer.new
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
        @socket       = TCPSocket.new(ip,port)
        @socket_mutex = Mutex.new
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
            #Log.debug("Packing message #{message.type} for server", 8)
            packed_data = @message_buffer.pack_message(message)
            @socket.write_nonblock(packed_data)
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
                        begin
                            data = @socket.read_nonblock(@config[:buffer_size])
                            raise Errno::ECONNRESET if data.empty?
                            data_buffer += data
                            new_messages, data_buffer = @message_buffer.unpack_messages(data_buffer)
                            messages.concat(new_messages)
                        rescue Errno::EWOULDBLOCK,Errno::EAGAIN
                            IO.select([@socket])
                            retry
                        end
                    end
                    @server_mutex.synchronize { @server_message_buffer.concat(messages) }
                end
            rescue Errno::ECONNRESET,EOFError
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
        @client_listen_thread = Thread.new do
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
