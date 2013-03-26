require 'uri'

class Symbol
    def title
        self.to_s.gsub(/_/, ' ').gsub(/(^| )(.)/) { "#{$1}#{$2.upcase}" }
    end

    def text
        self.to_s.gsub(/_/, ' ')
    end
end

class String
    def sentence
        # Capitalize the beginning.
        word = self.gsub(/^(\w)/) { $1.upcase }
        # Clobber underscores.
        word.gsub!(/_/, ' ')
        # Drop whitespace before punctuation.
        word.gsub!(/\s+([\,\.\?\!])/, '\1')
        # Add ending punctuation, if it doesn't already exist.
        word += '.' unless word.match(/[\.\!\?]['"]?$/)
        # Swap the sentence punctuation with the quote.
        word.gsub!(/(['"]?)([\.\!\?])?/, '\2\1')
        # Whitespace cleanup.
        word.gsub!(/^\s+/, '')
        word
    end

    def title
        self.split(' ').map(&:capitalize).join(' ')
    end

    def capitalized?
        !!(self.to_s[0].chr.match(/[A-Z]/))
    end

    def escape
        URI.escape(self)
    end

    def unescape
        URI.unescape(self)
    end
end

class Object
    def self.format_arbitrary(object)
        case object
        when String, Symbol, NilClass, TrueClass, FalseClass
            object.inspect
        when Numeric, Module
            object.to_s
        else
            object.class.to_s
        end
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
                    Object.format_arbitrary(element)
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
                    Object.format_arbitrary(value)
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
