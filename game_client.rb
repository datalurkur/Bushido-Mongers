require 'client_base'

require 'state'
require 'states/login_state'

require 'client_interface'

class GameClient < ClientBase
    include StateMaintainer

    def initialize(ip,port,interface,initial_state={})
        super(ip,port)

        @interface = interface

        internal_state=initial_state
        set_state(LoginState.new(self))

        @running = true
        start_main_loop
    end

    def running?; @running; end

    def start_main_loop
        while @running
            get_client_messages.each do |message|
                current_state.from_client(message)
            end

            get_server_messages.each do |message|
                current_state.from_server(message)
            end
        end
    end

    def stop
        @running = false
    end

    def send_to_client(message)
        @context = message
        @interface.generate(message)
    end

    def get_from_client(text)
        ret = @interface.parse(@context,text)
        @context = nil
        ret
    end
end
