require './net/game_server'

class ReproServer < GameServer
    def initialize(config, repro_file)
        @repro       = Repro.load(repro_file)
        @repro_index = 0

        super(config, @repro.seed)
    end

    def next_event
        @repro.events[@repro_index]
    end

    def continue_replay
        while next_event
            n = next_event
            case n.type
            when :from_client
                Log.debug("Replaying event: #{n.data.inspect}")
                @repro_index += 1
                process_client_message(n.data, n.extra)
            when :to_client
                Log.debug("Waiting for event: #{n.data.inspect}")
                return true
            else
                Log.error("Unknown event type #{n.type.inspect}")
                @repro_index += 1
            end
        end
        return false
    end

    def send_to_client(socket, message)
        if next_event.data == message && next_event.extra == socket
            Log.debug("Matched incoming event: #{message.inspect}")
            @repro_index += 1
        elsif next_event.data == message
            Log.debug("Message expected for #{event.extra}, but received on #{socket}: #{message.inspect}")
        else
            Log.debug("Event out-of-order: (#{socket}) #{message.inspect} (expected (#{next_event.extra}) #{next_event.data.inspect})")
        end
    end
end
