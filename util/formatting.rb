class Symbol
    def to_title
        self.to_s.gsub(/_/, ' ').gsub(/(^| )(.)/) { "#{$1}#{$2.upcase}" }
    end
end

class String
    def sentence
        # Whitespace cleanup.
        word = self.gsub(/^\s+/, '')
        word.gsub!(/\s+([\.\?\!])$/, '\1')
        # Capitalize the beginning.
        word.gsub!(/^(\w)/) { $1.upcase }
        # Add ending punctuation, if it doesn't already exist.
        word.gsub!(/([\.\!\?])?$/) { $1 || '.' }
    end

    def title
        self.split(' ').map(&:capitalize).join(' ')
    end
end

class Array
    def to_formatted_string(prefix="", omit_braces=false)
        string = []

        inner_indent = omit_braces ? "" : "\t"

        string << (prefix + "[") unless omit_braces
        string.concat(if empty?
            [prefix + inner_indent + "<EMPTY>"]
        else
            collect do |element|
                case element
                when Array,Hash
                    element.to_formatted_string(prefix + inner_indent, omit_braces)
                when String
                    prefix + inner_indent + element
                else
                    prefix + inner_indent + element.inspect
                end
            end
        end)
        string << (prefix + "]") unless omit_braces

        string.join("\n")
    end
end

class Hash
    def to_formatted_string(prefix="", omit_braces=false)
        string = []

        inner_indent = omit_braces ? "" : "\t"

        string << (prefix + "{") unless omit_braces
        if empty?
            string << (prefix + inner_indent + "<EMPTY>")
        else
            longest_key = keys.inject(0) { |longest,key|
                [key.inspect.length, longest].max
            }
            each do |key, value|
                output        = key.inspect.ljust(longest_key) + " => "
                value_printed = false

                unless (Array === value) || (Hash === value)
                    output += value.inspect
                    value_printed = true
                end

                string << prefix + inner_indent + output
                unless value_printed
                    string << value.to_formatted_string(prefix + inner_indent + "\t", omit_braces)
                end
            end
        end
        string << (prefix + "}") unless omit_braces

        string.join("\n")
    end
end
