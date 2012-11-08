require 'message'

# Provides a set of tools for maintaining a state stack and state variables
module StateMaintainer
    def current_state
        raise "#{self.class} is stateless!" if @state_stack.empty?
        @state_stack.last
    end

    def set_state(state)
        @state_stack = [state]
    end

    def push_state(state)
        @state_stack << state
    end

    def pop_state
        raise "State stack is empty!" if @state_stack.empty?
        @state_stack.pop
    end

    def internal_state;       @internal_state ||= {};      end
    def internal_state=(val); @internal_state   = val;     end
    def set(var,value);       internal_state[var] = value; end
    def get(var);             internal_state[var];         end
end

# Parent class for classes which will control Client behavior
# Function stubs to be defined by state subclasses
class State
    def initialize(client)
        @client = client
    end

    def from_client(message)
        raise "Unhandled message #{message.type} encountered during client processing for #{self.class}"
    end

    def from_server(message)
        raise "Unhandled message #{message.type} encountered during server processing for #{self.class}"
    end
end
