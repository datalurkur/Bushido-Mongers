require 'socket'
require 'socket_utils'

require 'log'

# Provides a low-level interface to server communications
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
        packed_data = pack_message(message)
        @socket_mutex.synchronize {
            @socket.puts(packed_data)
        }
    end

    def start_processing_server_messages
        @socket_mutex          = Mutex.new
        @server_mutex          = Mutex.new
        @server_message_buffer = []
        @server_listen_thread  = Thread.new do
            Log.name_thread("server_polling")
            data_buffer = ""
            while(true)
                begin
                    lines = []
                    while lines.empty?
                        new_lines = buffer_socket_input(@socket, @socket_mutex, data_buffer)
                        lines.concat(new_lines)
                    end
                    @server_mutex.synchronize { @server_message_buffer.concat(lines) }
                rescue Exception => e
                    Log.debug(["Client failed to process input from socket",e.message,e.backtrace])
                end
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
            Log.name_thread("client_polling")
            while(true)
                input = get_from_client
                Log.debug("Received client message #{input.type}")
                @client_mutex.synchronize { @client_message_buffer << input }
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
