require './util/log'
require './util/message_buffer'
require './net/defaults'

class AutomationStack
    attr_reader :read_pipe

    def initialize
        @state          = nil
        @config         = {}
        @response_procs = {}
        @message_buffer = MessageBuffer.new
    end

    def setup
        @read_pipe, @write_pipe = IO.pipe
    end

    def teardown
        @read_pipe.close;  @read_pipe = nil
        @write_pipe.close; @write_pipe = nil
        @message_buffer.report
    end

    def set_config(config); @config = config; end
    def get_config;         @config;          end

    def set_state(state); @state = state; end
    def get_state;        @state;         end
    def clear_state;      @state = nil;   end

    def specify_response_for(type, args={}, &block)
        raise(ArgumentError, "Block required for response definition.") unless block_given?
        data_hash = args.merge(:type => type)
        @response_procs[data_hash] = block
    end

    def find_response_for(message)
        Log.debug(["Handling message #{message.type}", message.params], 4)
        matching_types = @response_procs.keys.select do |hash|
            Message.match_message(message, hash)
        end
        if matching_types.empty?
            Log.debug("No response found for #{message.type}", 2)
            nil
        else
            if matching_types.size > 1
                Log.debug("Found multiple matches for #{message.type}", 2)
            end
            @response_procs[matching_types.first]
        end
    end

    def gets
        message = nil
        until message
            Log.debug("Getting stack response", 6)
            data = @read_pipe.read_nonblock(DEFAULT_BUFFER_SIZE)
            message = @message_buffer.unpack_message(data)
        end
        message
    end

    def puts(message)
        Log.debug("Putting stack query", 6)
        response_proc = find_response_for(message)
        if response_proc
            response_proc.call(self, message)
        end
    end

    def put_response(response)
        @write_pipe.write(@message_buffer.pack_message(response))
    end
end
