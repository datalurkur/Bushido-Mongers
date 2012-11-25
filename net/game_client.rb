require 'net/client_base'

require 'state/state'
require 'state/states/connect_state'

# GameClient mostly functions as an input buffer and state container; it is also responsible for passing messages and interactables through the interface module for translation
# When it comes to actual game events and functionality, the state objects do all the heavy lifting
# GameClient basically gadflys for input events and passes any that come in to whatever state is currently controlling its behavior
class GameClient < ClientBase
    include StateMaintainer

    def initialize(interface, initial_config={})
        super()

        @interface = interface

        setup_state
        set_internal_config(initial_config)
    end

    def start(initial_state=ConnectState)
        super()
        initial_state.new(self, :set)
        @running = true
        start_main_loop
    end

    def stop
        @running = false
        super()
    end


    def running?; @running; end

    def start_main_loop
        while @running
            get_client_messages.each do |message|
                current_state.from_client(message)
            end

            get_server_messages.each do |message|
                Log.debug("Parsing message #{message.type}", 7)
                current_state.from_server(message)
            end
        end
    end

    def send_to_client(message)
        @interface.generate(message)
    end

    def get_from_client(text)
        @interface.parse(current_state.get_exchange_context, text)
    end
end
