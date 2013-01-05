class Symbol
    def to_title
        self.to_s.gsub(/_/, ' ').gsub(/(^| )(.)/) { "#{$1}#{$2.upcase}" }
    end
end

class String
    def sentence
        # Capitalize the beginning.
        word = self.gsub(/^(\w)/) { $1.upcase }
        # Add ending punctuation, if it doesn't already exist.
        word.gsub!(/([\.\!\?])?$/) { $1 || '.' }
        # Whitespace cleanup.
        word.gsub!(/^\s+/, '')
        # Drop whitespace before punctuation.
        word.gsub!(/\s+([\,\.\?\!])/, '\1')
        word
    end

    def title
        self.split(' ').map(&:capitalize).join(' ')
    end

    def capitalized?
        !!(self.to_s[0].chr.match(/[A-Z]/))
    end
end

class Array
    def to_formatted_string(prefix="", nest_prefix=true)
        if empty?
            (nest_prefix ? prefix : "") + "[ <EMPTY> ]"
        else
            string = []

            each_with_index do |element,i|
                data = if element.respond_to?(:to_formatted_string)
                    element.to_formatted_string(prefix + "  ", false)
                else
                    case element
                    when String
                        element
                    when Symbol
                        element.inspect
                    when Fixnum,Float
                        element.to_s
                    else
                        element.class.to_s
                    end
                end

                header = (i == 0) ? "[ " : "  "
                footer = (i == (size - 1)) ? " ]" : ""

                (header = prefix + header) if (nest_prefix || i != 0)
                string << (header + data + footer)
            end

            string.join("\n")
        end
    end
end

class Hash
    def to_formatted_string(prefix="", nest_prefix=true)
        if empty?
            (nest_prefix ? prefix : "") + "{ <EMPTY> }"
        else
            string = []

            longest_key = keys.inject(0) { |longest,key|
                [key.inspect.length, longest].max
            }
            each_with_index do |pair, i|
                key, value    = pair
                key_output    = key.inspect.ljust(longest_key) + " => "
                value_output  = if value.respond_to?(:to_formatted_string)
                    value.to_formatted_string(prefix + "    ", false)
                else
                    case value
                    when String,Symbol,Fixnum,Float
                        value.inspect
                    else
                        value.class.to_s
                    end
                end

                header     = (i == 0) ? "{ " : "  "
                footer     = (i == (size - 1)) ? " }" : ""
                pre_header = (nest_prefix || i != 0) ? prefix : ""

                if value_output.match(/\n/)
                    string << pre_header + header + key_output
                    string << prefix + "    " + value_output + footer
                else
                    string << pre_header + header + key_output + value_output + footer
                end
            end

            string.join("\n")
        end
    end
end
