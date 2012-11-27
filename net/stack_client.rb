require 'net/game_client'
require 'automation/stack'
require 'ui/client_interface'

class StackClient < GameClient
    attr_reader :stack
    def initialize(config={})
        @stack = AutomationStack.new
        super(MetaDataInterface,config)
    end

    def send_to_client(message)
        @stack.put_query(super(message))
    end

    def get_from_client
        super(@stack.get_response)
    end
end
