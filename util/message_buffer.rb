require 'thread'
require './util/log'
require './util/compression'

=begin

Message Spec:
    - 4-byte length (high bit is the compression flag)
    - N-byte Marshalled data block (compressed if the compression flag is set)

=end

class MessageBuffer
    COMPRESSION_THRESHOLD = 256
    COMPRESSION_MASK      = 0x80000000
    SIZE_MASK             = 0x7fffffff

    def initialize
        @queued_messages = []
        @buffer = ""

        clear_stats
    end

    def clear_stats
        @stats = {
            :in => {
                :max                => 0,
                :min                => 0,
                :total              => 0,
                :compressed         => 0,
                :count              => 0,
                :compressed_count   => 0
            },
            :out => {
                :max                => 0,
                :min                => 0,
                :total              => 0,
                :compressed         => 0,
                :count              => 0,
                :compressed_count   => 0
            }
        }

        @track_stats = true
    end

    def unpack_messages(data)
        messages = []

        @buffer += data

        while true
            break unless @buffer.size >= 4

            header      = @buffer.unpack("N")[0]
            next_length = (header & SIZE_MASK)
            compression = (header & COMPRESSION_MASK)

            Log.debug("Unpacking message of size #{next_length}", 6)
            if @buffer.size >= next_length + 4
                data_block = @buffer[4,next_length]
                data_size  = next_length
                @buffer    = @buffer[(next_length+4)..-1]

                if compression != 0
                    #Log.info("Unpacking message with header #{header.to_s(16)}")
                    data_block      = data_block.inflate
                    compressed_size = data_size
                    data_size       = data_block.size

                    if @track_stats
                        @stats[:in][:compressed]       += compressed_size
                        @stats[:in][:compressed_count] += 1
                    end
                end

                message = Marshal.load(data_block)
                messages << message

                if @track_stats
                    @stats[:in][:count]      += 1
                    @stats[:in][:total]      += data_size
                    @stats[:in][:max] = [@stats[:in][:max], data_size].max
                    @stats[:in][:min] = [@stats[:in][:min], data_size].min
                end
            else
                Log.warning("Buffering socket data: #{@buffer.size}b/#{next_length}b received (consider increasing buffer size for #{caller[0]})")
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
        data_block = Marshal.dump(message)
        data_size  = data_block.size
        header     = nil

        if data_size > COMPRESSION_THRESHOLD
            #Log.info("Packing a message with compression")
            data_block      = data_block.deflate
            compressed_size = data_block.size
            raise "Packet size exceeded maximum allowed size of #{COMPRESSION_MASK}" if compressed_size > COMPRESSION_MASK
            header = [compressed_size | COMPRESSION_MASK].pack("N")

            if @track_stats
                @stats[:out][:compressed]       += compressed_size
                @stats[:out][:compressed_count] += 1
            end
        else
            #Log.info("Packing a message withOUT compression")
            header = [data_size].pack("N")
        end

        if @track_stats
            @stats[:out][:total]      += data_size
            @stats[:out][:count]      += 1
            @stats[:out][:max] = [@stats[:out][:max], data_size].max
            @stats[:out][:min] = [@stats[:out][:min], data_size].min
        end

        header + data_block
    end

    def report
        @stats[:out][:avg]            = @stats[:out][:total]      / @stats[:out][:count] unless @stats[:out][:count] == 0
        @stats[:out][:compressed_avg] = @stats[:out][:compressed] / @stats[:out][:compressed_count] unless @stats[:out][:compressed_count] == 0
        @stats[:in][:avg]             = @stats[:in][:total]       / @stats[:in][:count] unless @stats[:in][:count] == 0
        @stats[:in][:compressed_avg]  = @stats[:in][:compressed]  / @stats[:in][:compressed_count] unless @stats[:in][:compressed_count] == 0
        Log.info(["Message buffer summary for #{caller[0]}", @stats])
        clear_stats
    end
end
