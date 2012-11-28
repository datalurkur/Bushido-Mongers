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
        @eids      = 0

        @previous_result = nil

        case method
        when :set;  @client.set_state(self)
        when :push; @client.push_state(self)
        end
    end

    def pass_to_client(message)
        @client.send_to_client(message)
    end

    def from_client(message)
        unless process_exchange(message, :client)
            if message.type == :raw_command
                Log.debug("Discarding raw command #{message.command}")
            else
                Log.debug(["Unhandled message #{message.type} encountered during client processing for #{self.class}", caller])
            end
        end
    end

    def from_server(message)
        case message.type
        when :connection_reset
            pass_to_client(message)
            @client.disconnect
            ConnectState.new(@client, :set)
        else
            unless process_exchange(message, :server)
                Log.debug(["Unhandled message #{message.type} encountered during server processing for #{self.class}", caller])
            end
        end
    end

    def define_exchange(type, opt_args={}, &on_finish)
        id = @eids
        @eids += 1
        @exchanges[id] = {
            :type      => type,
            :on_finish => on_finish,
        }
        @exchanges[id].merge!(opt_args)
        Log.debug("Defined exchange #{id} with params #{@exchanges[id].inspect}")
        id
    end

    def define_exchange_chain(ordered_list, &on_finish)
        base_id = @eids
        ordered_list.each_with_index do |element, i|
            type     = element[0]
            opt_args = element[1]

            if (i+1) == ordered_list.size
                define_exchange(type, opt_args, &on_finish)
            else
                define_exchange(type, opt_args.merge(:next => base_id + i + 1))
            end
        end
        base_id
    end

    def begin_exchange(id)
        raise "Undefined data exchange #{id}" unless @exchanges[id]
        set_exchange_context(id, @previous_result)
        if get_exchange_target == :client
            @client.send_to_client(get_exchange_context)
        else
            @client.send_to_server(get_exchange_context)
        end
    end

    def set_exchange_context(id, previous_result)
        params = @exchanges[id]
        @current_exchange = case params[:type]
        when :text_field
            unless params.has_key?(:field)
                raise "Text fields must be given an identifier"
            end
            Message.new(:text_field, {:field => params[:field]})
        when :choose_from_list
            unless params.has_key?(:field)
                raise "Choice fields must be given an identifier"
            end
            choices = if params[:choices_from]
                previous_result[params[:choices_from]]
            else
                params[:choices]
            end
            Message.new(:choose_from_list, {:field => params[:field], :choices => choices})
        when :server_query
            Log.debug(["Querying server with params", params])
            Message.new(params[:query_method], params[:query_params] || {})
        else
            raise "Unhandled exchange type #{params[:type]}"
        end

        @exchange_id     = id

        @exchange_target = case params[:type]
        when :server_query, :fast_query
            :server
        when :text_field, :choose_from_list
            :client
        end
    end

    def clear_exchange_context
        @current_exchange = nil
        @exchange_id      = nil
        @exchange_target  = nil
    end

    def get_exchange_context
        @current_exchange
    end

    def get_exchange_id
        @exchange_id
    end

    def get_exchange_target
        @exchange_target
    end

    def process_server_exchange(message)
        id      = get_exchange_id
        context = get_exchange_context
        clear_exchange_context

        if message.type == :invalid_query
            Log.debug("Server exchange failed - #{message.reason}")
            return false
        else
            if context.has_param?(:field) && message.has_param?(context.field)
                result = message.send(context.field)
                Log.debug("Setting client field #{context.field} to #{result} based on server input")
                @client.set(context.field, result)
                @previous_result = result
            else
                if context.has_param?(:field)
                    @client.set(context.field, message.params)
                end
                @previous_result = message.params
            end
            return true
        end
    end

    def process_client_exchange(message)
        id      = get_exchange_id
        context = get_exchange_context
        clear_exchange_context

        if message.type == :invalid_input
            # Exchange failed, retry
            begin_exchange(id)
            return false
        else
            if context.has_param?(:field)
                Log.debug("Setting client field #{context.field} to #{message.input} based on client input")
                @client.set(context.field, message.input)
                @previous_result = message.input
            end
            return true
        end
    end

    def process_exchange(message, origin)
        Log.debug(["Attempting to process #{origin} exchange #{message.type}", message.params], 7)
        context = get_exchange_context
        id      = get_exchange_id

        if context && origin == get_exchange_target
            result = if origin == :server
                process_server_exchange(message)
            else
                process_client_exchange(message)
            end

            if result
                if @exchanges[id][:on_finish]
                    @exchanges[id][:on_finish].call(@previous_result)
                end

                if @exchanges[id][:next]
                    begin_exchange(@exchanges[id][:next])
                else
                    @previous_result = nil
                end
            end
            return true
        else
            Log.debug("No context present or origin and target do not match", 7)
            return false
        end
    end
end
