require 'server'

class DebugServer < Server
    def send(client,message)
        puts "#{client}: #{message}"
    end

    def start
        @recv_thread = Thread.new do
            while(true)
                input = gets
                begin
                    input_array = input.strip.split(/:/) || []
                    client = input_array[0]
                    message = input_array[1..-1].join.strip
                    unless message.empty?
                        process_client_command(client,message)
                    end
                rescue Exception => e
                    debug("Failure processing message: #{e.message}")
                    debug(e.backtrace)
                end
            end
        end

        super()
    end
end
