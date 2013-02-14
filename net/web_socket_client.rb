require './net/defaults'
require './net/game_client'
require './net/web_socket_reader'
require './ui/client_interface'
require './util/message_buffer'

# Acts in place of a normal remote client for IRC users, interacting with the IRCConduit instead of the console (or whatever)
class WebSocketClient < GameClient
    def initialize(socket, local_port)
        @write_mutex            = Mutex.new
        @read_pipe, @write_pipe = IO.pipe
        @reader                 = WebSocketReader.new
        @web_socket             = socket

        super(VerboseInterface)
        connect("localhost", local_port)
        start(LoginState)

        @listen_thread = Thread.new do
            reader = WebSocketReader.new
            while true
                begin
                    payload = reader.read(@web_socket)
                    case payload.opcode
                    when WebSocketPayload::TextFrame
                        @write_pipe.write(@message_buffer.pack_message(payload.data))
                    else
                        raise(NotImplementedError, "Unknown opcode #{payload.opcode}")
                    end
                rescue Errno::ECONNRESET,EOFError,IOError
                    Log.debug("WebSocket disconnected", 7)
                    break
                rescue Exception => e
                    Log.error(["Failed to read from WebSocket", e.class, e.message, e.backtrace])
                    break
                end
            end
        end
    end

    def send_to_client(message)
        if message.type == :connection_reset
            @listen_thread.kill
            stop
            return
        end

        @write_mutex.synchronize do
            data    = super(message)
            payload = WebSocketPayload.new(data).pack
            @web_socket.write_nonblock(payload)
        end
    end

    def get_client_stream
        @read_pipe
    end

    # Called from a thread in ClientBase
    def get_from_client
        message = nil
        until message
            data = @read_pipe.read_nonblock(DEFAULT_BUFFER_SIZE)
            message = @message_buffer.unpack_message(data)
        end
        super(message)
    end
end
