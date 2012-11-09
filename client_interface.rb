class Symbol
    def to_title
        self.to_s.gsub(/_/, ' ').gsub(/(^| )(.)/) { "#{$1}#{$2.upcase}" }
    end
end

# The purpose of the interface modules is to provide an abstraction layer for converting messages to and from whatever form they need to be in to be consumed and processed
# In the case of the user, this will take on the form of various text formats or commands to a GUI
# In the case of an AI, this will be something more like meta-data to allow simple decision making sans-text-parsing
module TextInterface
    def generate(message)
        case message.type
        when :notify; message.text
        when :query;  query(message.field)
        # While these would appear to be the same, one prompts a response (and this is very different to an AI!)
        when :choose; list(message.field.to_title,message.choices)
        when :list;   list(message.title,message.items)
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
            choice = get_choice(context,text)
            if choice
                Message.new(:choice,{:choice=>choice})
            else
                Message.new(:invalid_choice)
            end
        else
            raise "Unhandled client message type #{context.type}"
        end
    end

    def decorate(list,style)
        return ["[none]"] if list.empty?
        case style
        when :number
            (0...list.size).collect { |i| "(#{i}) #{list[i]}" }
        when :letter
            raise "Feature unimplemented"
        when :bullet
            list.collect { |i| "-#{i}" }
        end
    end
end

# Provides concise text
module SlimInterface
    extend TextInterface

    class << self
        def query(field)
            "Enter #{field.to_title}:"
        end

        def list(subject,items)
            ([subject] + decorate(items,style)).join(" ")
        end

        def get_choice(context,text)
            index = text.to_i
            unless (0...context.choices.size).include?(index)
                nil
            else
                context.choices[index]    
            end
        end
    end
end

# Provides verbose, nicely-formatted text
module VerboseInterface
    extend TextInterface

    class << self
        def query(field)
            "Enter #{field.to_title}:"
        end

        def list(subject,items,style=:number)
            ([subject] + decorate(items,style)).join("\n")
        end

        def get_choice(context,text)
            index = text.to_i
            unless (0...context.choices.size).include?(index)
                nil
            else
                context.choices[index]    
            end
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
            text
        end
    end
end
