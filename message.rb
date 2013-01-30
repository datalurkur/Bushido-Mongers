require './util/log'

# Generic message defining, creation, checking, and delegation
# Used in lots of places
class Message
    class << self
        def define(type, message_class, required_args=[], text=nil)
            raise(ArgumentError, "Message class must be a symbol, #{message_class.class} provided")      unless (Symbol === message_class)
            raise(ArgumentError, "Required arguments must be an array, #{required_args.class} provided") unless (Array === required_args)
            types[type] = {
                :required_args => required_args,
                :message_class => message_class || type,
                :default_args  => {}
            }
            (types[type][:default_args][:text] = text) unless text.nil?
        end

        def types
            @types ||= {}
        end

        def message_class_of(type)
            types[type][:message_class]
        end

        def type_defined?(type)
            types.has_key?(type)
        end

        def required_args(type)
            types[type][:required_args]
        end

        def listeners(core, message_class)
            @listeners                      ||= {}
            @listeners[core]                ||= {}
            @listeners[core][message_class] ||= [] 
            @listeners[core][message_class]
        end

        def get_listeners_for(core, type)
            message_class = message_class_of(type)
            listeners(core, message_class) + listeners(core, :all)
        end

        def register_listener(core, message_class, listener)
            Log.debug("#{listener.class} starts listening for #{message_class} messages", 6)
            listeners(core, message_class) << listener
            listeners(core, message_class).uniq!
        end

        def unregister_listener(core, message_class, listener)
            Log.debug("#{listener.class} stops listening for #{message_class} messages", 6)
            listeners(core, message_class).delete(listener)
        end

        def dispatch(core, type, args={})
            m = Message.new(type, args)
            sent_to = []
            while (next_listener = (get_listeners_for(core, type) - sent_to).first)
                next_listener.process_message(m)
                sent_to << next_listener
            end
        end

        def check_message(type, args)
            raise(ArgumentError, "Unknown message type #{type}") unless type_defined?(type)
            required_args(type).each do |arg|
                unless args.has_key?(arg) && args[arg]
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

        def default_args(type)
            types[type][:default_args]
        end
    end

    def initialize(type, args={})
        Message.check_message(type, args)
        @type = type
        @args = Message.default_args(type).merge(args)

        self
    end

    def type; @type; end

    def message_class; Message.message_class_of(@type); end

    def report
        [@type, @args]
    end

    def has_param?(name)
        @args.has_key?(name)
    end

    def params
        @args
    end

    def alter_params(&block)
        return unless block_given?
        @args = block.call(@args)
    end

    def method_missing(name, *args)
        unless @args[name]
            raise(StandardError, "No parameter #{name} for message type #{type}.")
        end
        @args[name]
    end
end

require './message_defs'
