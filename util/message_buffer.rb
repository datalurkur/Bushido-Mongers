require 'thread'
require './util/log'

class MessageBuffer
    def initialize
        @queued_messages = []
        @buffer = ""
    end

    def unpack_messages(data)
        messages = []

        @buffer += data

        while true
            break unless @buffer.size >= 4
            next_length = @buffer.unpack("N")[0]
            Log.debug("Unpacking message of size #{next_length}", 6)
            if @buffer.size >= next_length + 4
                message = Marshal.load(@buffer[4,next_length])
                messages << message
                @buffer = @buffer[(next_length+4)..-1]
            else
                Log.warning("Buffering socket data: #{@buffer.size}b/#{next_length}b received (consider increasing buffer size")
                break
            end
        end

        messages
    end

    def unpack_message(data)
        messages = unpack_messages(data)
        @queued_messages.concat(messages)
        Log.warning("Multiple messages back-queued") unless @queued_messages.size <= 1
        @queued_messages.shift
    end

    # Take a message and pack it into network format
    def pack_messages(messages)
        data = ""
        messages.each do |message|
            data += pack_message(message)
        end
        data
    end

    def pack_message(message)
        #Log.debug(["Packing message", message.report], 6)
        packed_data = Marshal.dump(message)
        length      = packed_data.size
        [length].pack("N") + packed_data
    end
end
