require 'message'

# Provides a set of tools for maintaining a state stack and state variables
module StateMaintainer
    def setup_state
        @internal_config = {}
        @var_mutex       = Mutex.new
    end

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

    def get_internal_config;      @internal_config;       end
    def set_internal_config(val); @internal_config = val; end

    def set(var,value)
        @var_mutex.synchronize { get_internal_config[var] = value }
    end
    def unset(var)
        @var_mutex.synchronize { get_internal_config.delete(var) }
    end
    def get(var)
        @var_mutex.synchronize { get_internal_config[var] }
    end
end

# Parent class for classes which will control Client behavior
# Function stubs to be defined by state subclasses
class State
    def initialize(client, method=nil)
        @client    = client
        @exchanges = {}

        case method
        when :set;  @client.set_state(self)
        when :push; @client.push_state(self)
        end
    end

    def from_client(message)
        unless process_exchange(message, :client)
            Log.debug(["Unhandled message #{message.type} encountered during client processing for #{self.class}", caller])
        end
    end

    def from_server(message)
        case message.type
        when :connection_reset
            @client.disconnect
            @client.send_to_client(Message.new(:notify, {:text=>"The connection with the server has been lost"}))
            ConnectState.new(@client, :set)
        else
            unless process_exchange(message, :server)
                Log.debug(["Unhandled message #{message.type} encountered during server processing for #{self.class}", caller])
            end
        end
    end

    def define_exchange(field,type,opt_args={},&on_finish)
        @exchanges[field] = {
            :type      => type,
            :on_finish => on_finish,
        }
        @exchanges[field].merge!(opt_args)
    end

    def define_exchange_chain(ordered_list,&on_finish)
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
                @exchanges[field].merge!(opt_args)
            end
        end
    end

    def begin_exchange(field)
        raise "Undefined data exchange for #{field}" unless @exchanges[field]
        set_exchange_context(field)
        if get_exchange_target == :client
            @client.send_to_client(get_exchange_context)
        else
            @client.send_to_server(get_exchange_context)
        end
    end

    def set_exchange_context(field)
        params = @exchanges[field]
        @current_exchange = case params[:type]
        when :text_field
            Message.new(:text_field)
        when :choose_from_list
            choices = if params[:choices_from]
                @client.get(params[:choices_from])
            else
                params[:choices]
            end
            Message.new(:choose_from_list, {:choices => choices})
        when :fast_query
            Log.debug(["Fast-querying with params", params])
            Message.new(:fast_query, {:field => field})
        when :server_query
            Log.debug(["Querying server with params", params])
            Message.new(params[:query_method], params[:query_params] || {})
        else
            raise "Unhandled exchange type #{params[:type]}"
        end

        @exchange_field = field

        @exchange_target = case params[:type]
        when :server_query
            :server
        when :text_field, :choose_from_list
            :client
        end
    end

    def clear_exchange_context
        @current_exchange = nil
        @exchange_field   = nil
        @exchange_target  = nil
    end

    def get_exchange_context
        @current_exchange
    end

    def get_exchange_field
        @exchange_field
    end

    def get_exchange_target
        @exchange_target
    end

    def process_server_exchange(message)
        field = get_exchange_field
        clear_exchange_context

        if message.type == :invalid_request
            Log.debug("Server exchange failed - #{message.reason}")
            return false
        else
            Log.debug("Setting client field #{field} to #{message.send(field)} based on server input")
            @client.set(field, message.send(field))
            return true
        end
    end

    def process_client_exchange(message)
        field   = get_exchange_field
        context = get_exchange_context
        clear_exchange_context

        if message.type == :invalid_input
            # Exchange failed, retry
            begin_exchange(field)
            return false
        else
            Log.debug("Setting client field #{field} to #{message.input} based on client input")
            @client.set(field, message.input)
            return true
        end
    end

    def process_exchange(message, origin)
        context = get_exchange_context
        field   = get_exchange_field

        if context && origin == get_exchange_target
            result = if origin == :server
                process_server_exchange(message)
            else
                process_client_exchange(message)
            end

            if result
                if @exchanges[field][:on_finish]
                    @exchanges[field][:on_finish].call(message.input)
                end

                if @exchanges[field][:next]
                    begin_exchange(@exchanges[field][:next])
                end
            end
            return true
        else
            return false
        end
    end
end
