module TextInterface
    def generate(message)
        case message.type
        when :notify; message.text
        when :query; query(message.field)
        when :choose; list(message.field,message.choices)
        else
            raise "Unhandled client message type #{message.type}"
        end
    end

    def parse(context,text)
        unless context
            return Message.new(:raw_command,{:command=>text})
        end

        case context.type
        when :query
            Message.new(:response,{:value=>text})
        when :choose
            Message.new(:choice,{:choice=>get_choice(context,text)})
        else
            raise "Unhandled client message type #{context.type}"
        end
    end
end

# Provides concise text
module SlimInterface
    extend TextInterface

    class << self
        def query(field)
            "Enter #{field}:"
        end

        def list(items)
            raise "Feature not yet implemented"
        end

        def get_choice(context,text)
            raise "Feature not yet implemented"
        end
    end
end

# Provides verbose, nicely-formatted text
module VerboseInterface
    extend TextInterface

    class << self
        def query(field)
            "Enter #{field}:"
        end

        def list(items)
            raise "Feature not yet implemented"
        end

        def get_choice(context,text)
            raise "Feature not yet implemented"
        end
    end
end

# Provides meta-data for AI or non-textual clients
module MetaDataInterface
    class << self
        def query(field)
            [:query,field]
        end

        def list(items)
            [:list,items]
        end

        def get_choice(context,text)
            raise "Feature not yet implemented"
        end
    end
end
