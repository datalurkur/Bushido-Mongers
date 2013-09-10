require './util/log'

# Generic message defining, creation, checking, and delegation
# Used in lots of places
class MessageBase
    class << self
        def setup(core)
            @listeners       ||= {}
            @listeners[core]   = {}
            types.each_key do |type|
                @listeners[core][type] = []
            end
            klasses.each_key do |klass|
                @listeners[core][klass] = []
            end
            @listener_state_dirty = []
        end

        def define(type, message_class, required_args=[], text=nil)
            raise(ArgumentError, "Message class must be a symbol, #{message_class.class} provided")      unless (Symbol === message_class)
            raise(ArgumentError, "Required arguments must be an array, #{required_args.class} provided") unless (Array === required_args)
            raise(ArgumentError, "Message type already defined") if types.has_key?(type)
            klasses[message_class] ||= []
            klasses[message_class] << type
            types[type] = {
                :required_args => required_args,
                :message_class => message_class,
                :default_args  => {}
            }
            (types[type][:default_args][:text] = text) unless text.nil?
        end

        def types
            @types ||= {}
        end

        def klasses
            @klasses ||= {}
        end

        def type_defined?(type)
            types.has_key?(type)
        end

        def register_listener(core, message_type, listener)
            @listener_state_dirty[-1] = true unless @listener_state_dirty.empty?
            Log.debug("#{listener.class} starts listening for #{message_type} messages", 6)
            @listeners[core][message_type] << listener
            @listeners[core][message_type].uniq!
        end

        def unregister_listener(core, message_type, listener)
            @listener_state_dirty[-1] = true unless @listener_state_dirty.empty?
            Log.debug("#{listener.class} stops listening for #{message_type} messages", 6)
            @listeners[core][message_type].delete(listener)
        end

        def dispatch(core, type, args={})
            m = Message.new(type, args)

            message_class = types[type][:message_class]
            listener_list = (@listeners[core][type] + @listeners[core][message_class]).uniq

            sent_to = []
            @listener_state_dirty.push(false)
            while (next_listener = listener_list.shift)
                next_listener.process_message(m)
                sent_to << next_listener
                if @listener_state_dirty[-1]
                    listener_list = (@listeners[core][type] + @listeners[core][message_class]).uniq - sent_to
                end
            end
            @listener_state_dirty.pop
        end

        def check_message(type, args)
            raise(ArgumentError, "Unknown message type #{type}") unless type_defined?(type)
            types[type][:required_args].each do |arg|
                unless args.has_key?(arg)
                    raise(ArgumentError, "#{arg} required for message type #{type.inspect}.")
                end
            end
        end

        def match_message(message, hash)
            raise(ArgumentError, "Not a message: #{message.inspect}.") unless Message === message
            raise(ArgumentError, "Unknown message type #{type}.")      unless type_defined?(message.type)
            return false if hash[:type] && message.type != hash[:type]
            return hash.keys.reject { |k| k == :type }.all? { |k| (message.has_param?(k) && message.send(k) == hash[k]) }
        end
    end

    def initialize(type, args={})
        Message.check_message(type, args)
        @type = type
        @args = Message.types[type][:default_args].merge(args)

        self
    end

    def type; @type; end

    def message_class; Message.types[@type][:message_class]; end

    def report
        [@type, @args]
    end

    def has_param?(name)
        !@args[name].nil?
    end

    def params
        @args
    end

    def alter_params!(&block)
        return unless block_given?
        @args = block.call(@args)
    end

    def method_missing(name, *args)
        unless @args.has_key?(name)
            raise(StandardError, "No parameter #{name.inspect} for message type #{type.inspect}.")
        end
        @args[name]
    end

    def ==(other)
      return false if @type != other.type
      other.params.each do |param, val|
        return false if @args[param] != val
      end
      return true
    end
end
