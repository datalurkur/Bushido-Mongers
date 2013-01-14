require './net/game_client'
require './automation/stack'
require './ui/client_interface'

class StackClient < GameClient
    attr_reader :stack

    def initialize(config={})
        @stack = AutomationStack.new
        seize_control
        super(MetaDataInterface,config)
    end

    def release_control
        Log.debug("Releasing control to user")
        return unless AutomationStack === @pipeline
        @interface = VerboseInterface
        @pipeline.teardown
        @pipeline  = $stdin
    end

    def seize_control
        Log.debug("Seizing control from user")
        return if AutomationStack === @pipeline
        @interface = MetaDataInterface
        @pipeline  = @stack
        @pipeline.setup
    end

    def send_to_client(message)
        data = super(message)
        Log.debug("Sending to client: #{data.inspect}")
        @pipeline.puts(data)
    end

    def get_client_stream
        (AutomationStack === @pipeline) ? @pipeline.read_pipe : @pipeline
    end

    def get_from_client
        data = @pipeline.gets
        Log.debug("Returning from client: #{data.inspect}")
        super(data)
    end
end
