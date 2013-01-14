require 'socket'
require './net/defaults'
require './util/message_buffer'
require './util/cfg_reader'

class MuxedClientBase
    def initialize
        @setup  = false
        @config = {}
        @config[:buffer_size] = (CFGReader.get_param("net", :buffer_size) || DEFAULT_BUFFER_SIZE).to_i
        @message_buffer = MessageBuffer.new
    end

    def start
        @setup = true
    end

    def stop
        @setup = false
        teardown
    end

    def connect(ip, port)
        raise "Can't attempt to connect until client has started" unless @setup
        @socket = TCPSocket.new(ip,port)
    end

    def disconnect
        if @socket
            @socket.close
            @socket = nil
        end
    end

    def teardown
        disconnect
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

    def get_messages
        client_messages = []
        server_messages = []

        stream_list = [get_client_stream]
        stream_list << @socket if @socket
        ready_streams = IO.select(stream_list)

        #Log.debug(["Ready streams", ready_streams])

        ready_streams.first.each do |stream|
            Log.debug("Stream #{stream.class} is ready to provide data")
            if stream == @socket
                server_messages.concat(get_server_messages)
            else
                client_messages.concat(get_client_messages)
            end
        end

        [client_messages, server_messages]
    end

    private
    def get_server_messages
        messages = []
        begin
            begin
                data = @socket.read_nonblock(@config[:buffer_size])
                raise Errno::ECONNRESET if data.empty?
                new_messages = @message_buffer.unpack_messages(data)
                messages.concat(new_messages)
            rescue Errno::EWOULDBLOCK,Errno::EAGAIN
                IO.select([@socket])
                retry
            end
        rescue Errno::ECONNRESET,EOFError
            # Pass a fake server message informing the client that the connection was reset
            messages << Message.new(:connection_reset)
        rescue Exception => e
            Log.warning(["Exception occurred while getting server messages - #{e.message}", e.backtrace])
        end
        Log.debug(["Returning server messages", messages])
        messages
    end

    def get_client_messages
        messages = []
        begin
            if @setup && input = get_from_client
                raise RuntimeError, "Received non-message #{input.inspect} from client!" unless Message === input
                Log.debug("Received client message #{input.type}", 8)
                messages << input
            else
                Log.warning("#{@setup.inspect} / #{input.inspect}")
            end
        rescue Exception => e
            Log.warning(["Exception occurred while getting client messages - #{e.message}", e.backtrace])
        end
        Log.debug(["Returning client messages", messages])
        messages
    end
end
