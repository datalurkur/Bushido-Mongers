require './util/basic'
require './words/words'

# The purpose of the interface modules is to provide an abstraction layer for converting messages to and from whatever form they need to be in to be consumed and processed
# In the case of the user, this will take on the form of various text formats or commands to a GUI
# In the case of an AI, this will be something more like meta-data to allow simple decision making sans-text-parsing
module TextInterface
    def generate(message)
        case message.type
        when :text_field;       text_field(message.field)
        # While these would appear to be the same, one prompts a response (and this is very different to an AI!)
        when :choose_from_list; list(message.choices, message.field)
        when :list;             list(message.items)
        when :properties;       properties(message)
        else
            if message.has_param?(:text)
                if message.has_param?(:reason)
                    "#{message.text} - #{message.reason}"
                elsif message.has_param?(:result)
                    "#{message.text} - #{message.result}"
                else
                    message.text
                end
            else
                raise(ArgumentError, "Unhandled client message type #{message.type} : #{message.params.inspect}.")
            end
        end
    end

    def parse(context, text, target)
        text ||= ''
        if !context || target == :server
            Log.debug("No context for parsing input, returning raw command", 6)
            return Message.new(:raw_command,{:command=>text.chomp})
        end

        case context.type
        when :text_field
            Message.new(:valid_input, {:input=>text.chomp})
        when :choose_from_list
            choice = get_choice(context,text.chomp)
            if choice
                Message.new(:valid_input, {:input=>choice})
            else
                Message.new(:invalid_input)
            end
        else
            raise(ArgumentError, "Unhandled client message type #{context.type}.")
        end
    end

    def decorate(list, style)
        return ["[none]"] if list.empty?
        case style
        when :number
            (0...list.size).collect { |i| "(#{i+1}) #{list[i]}" }
        when :letter
            raise(NotImplementedError)
        when :bullet
            list.collect { |i| "-#{i}" }
        end
    end
end

# Provides concise text
module SlimInterface
    extend TextInterface

    class << self
        def text_field(field)
            field.title
        end

        def list(items, field=nil, style=:number)
            title = field ? "=#{field.title}= " : ""
            title + decorate(items, style).join(" ")
        end

        def properties(message)
            message.properties.collect { |k,v| "#{k}=>#{v}" }.join(" ")
        end

        def get_choice(context, text)
            index = text.to_i
            unless (1..context.choices.size).include?(index)
                nil
            else
                context.choices[index-1]
            end
        end
    end
end

# Provides verbose, nicely-formatted text
module VerboseInterface
    extend TextInterface

    class << self
        def text_field(field)
            field.title
        end

        def list(items, field=nil, style=:number)
            title = field ? "=#{field.title}=\n" : ""
            title + decorate(items, style).join("\n")
        end

        def properties(message)
            if message.field == :action_results
                case message.properties[:command]
                when :inspect
                    target = message.properties[:target]
                    case target[:type]
                    when :room
                        return Words.gen_room_description(target)
                    else
                        if target[:is_type].include?(:corporeal)
                            return Words.describe_corporeal(target)
                        elsif target[:is_type].include?(:composition_root)
                            return Words.describe_composition(target)
                        elsif target[:is_type].include?(:item)
                            return Words.gen_sentence(message.properties)
                        else
                            return "I don't know how to describe a #{target[:type].inspect}, bother zphobic to fix this"
                        end
                    end
                when :move
                    return Words.gen_move_description(message.properties)
                when :attack, :get, :drop, :hide, :unhide
                    return Words.gen_sentence(message.properties)
                when :stats
                    return Words.describe_stats(message.properties)
                when :help
                    return Words.describe_help(message.properties)
                else
                    return "I don't know how to express the results of a(n) #{message.properties[:command]}, pester zphobic to work on this"
                end
            elsif message.field == :game_event
                case message.properties[:event_type]
                when :object_destroyed
                    return Words.gen_copula(message.properties.merge(:verb=>:destroy))
                else
                    return "I don't know how to express a game event of type #{message.properties[:event_type]}"
                end
            elsif message.field == :server_link
                return "Server Link: http://#{message.properties[:host]}#{message.properties[:uri]}"
            else
                return message.properties.to_formatted_string("", true)
            end
        end

        def get_choice(context, text)
            index = text.to_i
            unless (1..context.choices.size).include?(index)
                nil
            else
                context.choices[index-1]
            end
        end
    end
end

# Provides meta-data for AI or non-textual clients
module MetaDataInterface
    class << self
        def generate(message)
            message
        end

        def parse(context, text, target)
            if !context || target == :server
                Log.debug("No context for parsing input, returning raw command")
                Message.new(:raw_command,{:command=>text})
            else
                Message.new(:valid_input, {:input=>text})
            end
        end
    end
end
