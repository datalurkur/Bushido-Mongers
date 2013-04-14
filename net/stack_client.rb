require './net/game_client'
require './automation/stack'
require './ui/client_interface'

class StackClient < GameClient
    attr_reader :stack

    def initialize(config={})
        @stack = AutomationStack.new
        setup_control_pipeline
        super(MetaDataInterface,config)
    end

    def setup_control_pipeline
        @interface = MetaDataInterface
        @pipeline  = @stack
        @pipeline.setup
    end

    def setup_user_pipeline
        @interface = VerboseInterface
        @pipeline.teardown
        @pipeline  = Kernel
    end

    def release_control
        Log.info("Releasing control to user")
        return unless AutomationStack === @pipeline
        restart { setup_user_pipeline }
    end

    def seize_control
        Log.info("Seizing control from user")
        return if AutomationStack === @pipeline
        restart { setup_control_pipeline }
    end

    def send_to_client(message)
        @pipeline.puts(super(message))
    end

    def get_client_stream
        if AutomationStack === @pipeline
            @pipeline.read_pipe
        else # Kernel
            $stdin
        end
    end

    def get_from_client
        super(@pipeline.gets)
    end
end
