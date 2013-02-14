class WebSocketPayload
    attr_reader :fin, :opcode, :length, :data

    # Opcodes:
    ContinuationFrame   = 0x0
    TextFrame           = 0x1
    BinaryFrame         = 0x2
    #  0x3 - 0x7 reserved
    Ping                = 0x9
    Pong                = 0xa
    #  0xb - 0xf reserved

    def initialize(data, fin=true, opcode=TextFrame, mask=nil)
        @fin    = fin
        @opcode = opcode
        @mask   = mask
        @length = data.length

        if @mask
            @data = data
            (0...@length).each do |i|
                @data[i] = data[i] ^ @mask[i % 4]
            end
        else
            @data = data
        end
    end

    def pack
        first_byte   = [@fin ? (@opcode | 0x80) : @opcode].pack("C")
        length_bytes = if @length <= 125
            [@mask ? (@length | 0x80) : @length].pack("C")
        elsif @length <= 65535
            [
                @mask ? (126 | 0x80) : 126,
                @length
            ].pack("CS")
        else
            [
                @mask ? (127 | 0x80) : 127,
                @length
            ].pack("CN")
        end

        first_byte + length_bytes + (@mask || "") + (@data || "")
    end
end

class WebSocketReader
    def initialize
        @buffer = ""
        @state  = :first_byte
    end

    def read(socket)
        buffer = ""
        begin
            buffer = socket.read_nonblock(DEFAULT_BUFFER_SIZE)
            raise(Errno::ECONNRESET) if buffer.empty?
        rescue Errno::EWOULDBLOCK,Errno::EAGAIN
            IO.select([socket])
            retry
        rescue EOFError => e
            raise(e)
        rescue Exception => e
            Log.debug(["Error reading data", e.message, e.backtrace])
            raise(e)
        end

        @buffer += buffer

        while true
            case @state
            when :first_byte
                break if @buffer.empty?
                first_byte = @buffer.slice!(0)

                @fin    = first_byte & 0x80
                @opcode = first_byte & 0x7f

                @state  = :first_length_byte
            when :first_length_byte
                break if @buffer.empty?
                first_byte = @buffer.slice!(0)

                @has_mask = first_byte & 0x80
                unmasked_length = first_byte & 0x7f

                case unmasked_length
                when 127
                    @state  = :four_byte_length
                when 126
                    @state  = :two_byte_length
                else
                    @length = unmasked_length
                    @state  = @has_mask ? :mask_bytes : :payload
                end
            when :four_byte_length
                break if @buffer.size < 4
                @length = @buffer.slice!(0,4).unpack("N").first
                @state  = @has_mask ? :mask_bytes : :payload
            when :two_byte_length
                break if @buffer.size < 2
                @length = @buffer.slice!(0,2).unpack("S").first
                @state  = @has_mask ? :mask_bytes : :payload
            when :mask_bytes
                @mask  = @buffer.slice!(0,4)
                @state = :payload
            when :payload
                break if @buffer.size < @length
                @data  = @buffer.slice!(0, @length)
                @state = :first_byte
                payload = WebSocketPayload.new(@data, @fin, @opcode, @mask)
                @fin = @opcode = @length = @has_mask = @mask = @data = nil
                return payload
            end
        end
    end
end
