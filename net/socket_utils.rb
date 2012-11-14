require 'thread'

# Miscellaneous shared code and utilities
module SocketUtils
    STATIC_SOCKET_READ_SIZE = 1024
    DEFAULT_LISTEN_PORT = 9999

    # For a given socket protected by a mutex, take a partial buffer and poll for new messages
    # If new messages are received (completely), unpack them from network format and recast them
    # Returns completed messages
    def buffer_socket_input(socket, mutex, buffer)
        messages   = []
        data_in = nil

        mutex.synchronize {
            begin
                data_in = socket.read_nonblock(STATIC_SOCKET_READ_SIZE)
            rescue
            end
        }
        return [] unless data_in

        buffer += data_in
        while true
            break unless buffer.size >= 4
            next_length = buffer.unpack("N")[0]
            if buffer.size >= next_length + 4
                message = Marshal.load(buffer[4,next_length])
                raise "Invalid object received: #{message.class} #{message.inspect}" unless Message === message
                Log.debug(message.report)
                messages << message
                buffer = buffer[(next_length+1)..-1]
            else
                break
            end
        end

        messages
    end

    # Take a message and pack it into network format
    def pack_message(message)
        Log.debug(message.report)
        packed_data = Marshal.dump(message)
        length      = packed_data.size
        [length].pack("N") + packed_data
    end
end