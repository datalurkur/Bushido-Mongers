require './net/muxed_client_base'
require './state/state'
require './state/states/connect_state'

# GameClient mostly functions as an input buffer and state container; it is also responsible for passing messages and interactables through the interface module for translation
# When it comes to actual game events and functionality, the state objects do all the heavy lifting
# GameClient basically gadflys for input events and passes any that come in to whatever state is currently controlling its behavior
class GameClient < MuxedClientBase
    include StateMaintainer

    def initialize(interface, initial_config={})
        super()

        @interface = interface

        setup_state
        set_internal_config(initial_config)
    end

    def start(initial_state=ConnectState)
        return if @running
        super()
        initial_state.new(self)
        @running = true
        @running_thread = start_main_loop
    end

    def restart(&block)
        @running_thread.kill
        ret = block.call
        @running_thread = start_main_loop
        return ret
    end

    def stop
        return unless @running
        @running = false
        @running_thread.kill
        super()
    end

    def running?; @running; end

    def start_main_loop
        Thread.new do
            Log.name_thread("Loop")
            begin
                while @running
                    client_messages, server_messages = get_messages

                    Log.debug("Processing #{client_messages.size} client messages and #{server_messages.size} server messages", 6)

                    client_messages.each do |message|
                        Log.debug("Client message #{message.type}", 8)
                        current_state.from_client(message)
                    end

                    server_messages.each do |message|
                        Log.debug("Server message #{message.type}", 8)
                        current_state.from_server(message)
                    end
                end
            rescue Exception => e
                @running = false
                Log.error(["Client loop terminating abnormally", e.message, e.backtrace])
            end
        end
    end

    def send_to_client(message)
        @interface.generate(message)
    end

    def get_from_client(text)
        @interface.parse(current_state.get_exchange_context, text, current_state.get_exchange_target)
    end
end
