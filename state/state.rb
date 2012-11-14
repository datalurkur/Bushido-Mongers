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

    def get_internal_state;      @internal_state ||= {};          end
    def set_internal_state(val); @internal_state = val;           end
    def set(var,value);          get_internal_state[var] = value; end
    def unset(var);              get_internal_state.delete(var);  end
    def get(var);                get_internal_state[var];         end
end

# Parent class for classes which will control Client behavior
# Function stubs to be defined by state subclasses
class State
    def initialize(client)
        @client    = client
        @exchanges = {}
    end

    def from_client(message)
        process_exchange(message)
    end

    def from_server(message)
        Log.debug("Unhandled message #{message.type} encountered during server processing for #{self.class}")
    end

    def define_exchange(field,type,opt_args={},&on_finish)
        @exchanges[field] = {
            :type      => type,
            :on_finish => on_finish,
        }
        @exchanges[field].merge!(opt_args)
    end

    def define_exchange_chain(ordered_list,&on_finish)
        # anjean; write some validation here to ensure no infinite loops (unless someone might want that?)
        fields = ordered_list.collect { |args| args[0] }
        ordered_list.each_with_index do |args,i|
            field    = args[0]
            type     = args[1]
            opt_args = args[2] || {}

            fields << field
            if (i+1) == ordered_list.size
                define_exchange(field,type,opt_args,&on_finish)
            else
                @exchanges[field] = {
                    :type => type,
                    :next => fields[i+1],
                }
            end
        end
    end

    def begin_exchange(field)
        raise "Undefined data exchange for #{field}" unless @exchanges[field]
        exchange_message = set_exchange_context(field)
        @client.send_to_client(exchange_message)
    end

    def set_exchange_context(field)
        @current_exchange = case @exchanges[field][:type]
        when :text_field;       Message.new(:text_field,{:field=>field})
        when :choose_from_list; Message.new(:choose_from_list,{:field=>field,:choices=>@exchanges[field][:choices]})
        else;                   raise "Unhandled exchange type #{@exchanges[field]}"
        end
        @current_exchange
    end

    def clear_exchange_context
        @current_exchange = nil
    end

    def get_exchange_context
        @current_exchange
    end

    def process_exchange(message)
        context = get_exchange_context
        if context
            clear_exchange_context
            if message.type == :invalid_input
                # Exchange failed, retry
                begin_exchange(context.field)
            else
                @client.set(context.field,message.input)
                if @exchanges[context.field][:on_finish]
                    @exchanges[context.field][:on_finish].call(message.input)
                end
                if @exchanges[context.field][:next]
                    begin_exchange(@exchanges[context.field][:next])
                end
            end
        else
            Log.debug("No data requested, message \"#{message.type}\" discarded")
        end
    end
end
