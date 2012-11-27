require 'util/log'

# Generic message defining, creation, checking, and delegation
# Used in lots of places
class Message
    class << self
        def define(type, message_class, required_args=[], text=nil)
            raise "Message class must be a symbol, #{message_class.class} provided"      unless (Symbol === message_class)
            raise "Required arguments must be an array, #{required_args.class} provided" unless (Array === required_args)
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

        def listeners(message_class)
            Thread.current[:listeners] ||= {}
            Thread.current[:listeners][message_class] ||= []
            Thread.current[:listeners][message_class]
        end

        def get_listeners_for(type)
            message_class = message_class_of(type)
            listeners(message_class) + listeners(:all)
        end

        def register_listener(listener, message_class)
            listeners(message_class) << listener
            listeners(message_class).uniq!
        end

        def dispatch(type, args={})
            m = Message.new(type, args)
            l = get_listeners_for(type)
            Log.debug("Message falling upon deaf ears") if l.empty?
            l.each do |listener|
                listener.process_message(m)
            end
        end

        def check_message(type, args)
            raise "Unknown message type #{type}" unless type_defined?(type)
            required_args(type).each { |arg| raise "#{arg} required for #{type} messages" unless args.has_key?(arg) }
        end

        def match_message(message, hash)
            raise "Not a message: #{message.inspect}" unless Message === message
            raise "Unknown message type #{type}" unless type_defined?(message.type)
            return false if hash[:type] && message.type != hash[:type]
            return hash.keys.reject { |k| k == :type }.all? { |k| (message.has_param?(k) && message.send(k) == hash[k]) }
        end

        def default_args(type)
            types[type][:default_args]
        end
    end

    def initialize(type, args={})
        Log.debug(["Creating a message of type #{type}", args], 6)
        Message.check_message(type, args)
        @type = type
        @args = Message.default_args(type).merge(args)

        self
    end

    def type; @type; end

    def message_class; Message.message_class_of(@type); end

    def report
        "#{@type}: #{@args.inspect}"
    end

    def has_param?(name)
        @args.has_key?(name)
    end

    def params
        @args
    end

    def method_missing(name, *args)
        unless @args[name]
            raise "No parameter #{name} for message type #{type}"
        end
        @args[name]
    end
end

require 'message_defs'
