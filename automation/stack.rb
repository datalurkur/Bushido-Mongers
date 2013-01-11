require './util/log'

class AutomationStack
    def initialize
        @state              = nil
        @config             = {}
        @incoming_query     = nil
        @outgoing_responses = []
        @response_mutex     = Mutex.new

        @response_procs     = {}
    end

    def set_config(config); @config = config; end
    def get_config; @config; end

    def set_state(state); @state = state; end
    def get_state; @state; end
    def clear_state; @state = nil; end

    def specify_response_for(type, args={}, &block)
        raise "No response proc given" unless block_given?
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
        Log.debug("Getting stack response", 6)
        response = nil
        while response.nil?
            @response_mutex.synchronize { response = @outgoing_responses.shift }
        end
        response
    end

    def puts(message)
        Log.debug("Putting stack query", 6)
        response_proc = find_response_for(message)
        if response_proc
            response_proc.call(self, message)
        end
    end

    def put_response(response)
        Log.debug("Stack responding with #{response.inspect}", 6)
        @response_mutex.synchronize { @outgoing_responses << response }
        Log.debug("Done responding", 8)
    end
end
