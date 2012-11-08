require 'log'

class Message
    class << self
        def define(type,message_class=nil,required_args=[])
            raise "Message class must be a symbol, #{message_class.class} provided"      unless (Symbol === message_class)
            raise "Required arguments must be an array, #{required_args.class} provided" unless (Array === required_args)
            types[type] = {
                :required => required_args,
                :message_class => message_class || type
            }
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

        def required_args(message_class)
            types.keys.select { |k| types[k][:message_class] == message_class }
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

        def register_listener(listener,message_class)
            listeners(message_class) << listener
            listeners(message_class).uniq!
        end

        def dispatch(type,args={})
            m = Message.new(type,args)
            get_listeners_for(type).each do |listener|
                listener.process_message(m)
            end
        end

        def check_message(type,args)
            raise "Unknown message type #{type}" unless type_defined?(type)
            required_args(type).each { |arg| raise "#{arg} required for #{type} messages" unless args.has_key?(arg) }
        end
    end

    def initialize(type,args={})
        Message.check_message(type,args)
        @type = type
        @args = args

        self
    end

    def type; @type; end

    def report
        "#{@type}: #{@args.inspect}"
    end

    def method_missing(name,*args)
        unless @args[name]
            raise "No parameter #{name} for message type #{type}"
        end
        @args[name]
    end
end

require 'message_defs'
