require 'thread'
require './util/log'

# Miscellaneous shared code and utilities
module SocketUtils
    # TODO - Move these numbers into a config file
    DEFAULT_BUFFER_SIZE = 5096
    DEFAULT_LISTEN_PORT = 9999
    DEFAULT_IRC_PORT    = 7000
    DEFAULT_HTTP_PORT   = 8000
    DEFAULT_WEB_ROOT    = "web_data"

    # For a given socket protected by a mutex, take a partial buffer and poll for new messages
    # If new messages are received (completely), unpack them from network format and recast them
    # Returns completed messages
    def buffer_socket_input(buffer)
        messages = []

        while true
            break unless buffer.size >= 4
            next_length = buffer.unpack("N")[0]
            Log.debug("Unpacking message of size #{next_length}", 6)
            if buffer.size >= next_length + 4
                message = Marshal.load(buffer[4,next_length])
                raise "Invalid object received: #{message.class} #{message.inspect}" unless Message === message
                messages << message
                buffer = buffer[(next_length+4)..-1]
            else
                Log.warning("Buffering socket data: #{buffer.size}b/#{next_length}b received (consider increasing buffer size")
                break
            end
        end

        [messages, buffer]
    end

    # Take a message and pack it into network format
    def pack_message(message)
        Log.debug(["Packing message", message.report], 6)
        packed_data = Marshal.dump(message)
        length      = packed_data.size
        [length].pack("N") + packed_data
    end
end
