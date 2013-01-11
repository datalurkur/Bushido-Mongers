require './net/game_client'
require './automation/stack'
require './ui/client_interface'

class StackClient < GameClient
    attr_reader :stack
    def initialize(config={})
        @stack    = AutomationStack.new
        @pipeline = @stack
        super(MetaDataInterface,config)
    end

    def release_control
        Log.debug("Releasing control to user")
        stop_processing_client_messages
        @interface = VerboseInterface
        @pipeline  = Kernel
        start_processing_client_messages
    end

    def seize_control
        Log.debug("Seizing control from user")
        stop_processing_client_messages
        @interface = MetaDataInterface
        @pipeline  = @stack
        start_processing_client_messages
    end

    def send_to_client(message)
        @pipeline.puts(super(message))
    end

    def get_from_client
        super(@pipeline.gets)
    end
end
