require 'digest'

class Array
    def rand
        self[Kernel.rand(self.size)]
    end

    def contents_equivalent?(other)
        (other.size == self.size) && ((self & other).size == self.size)
    end

    def rand_from_intersection(other)
        (self & other).rand
    end
end

class Hash
    def to_sym
        self.each do |key, value|
            unless Symbol === value
                self[key] = value.to_sym
            end
        end
    end
end

class Range
    def &(other)
        case other
        when Array
            self.to_a & other
        when Range
            self.to_a & other.to_a
        when Fixnum
            self.to_a & [other]
        else
            raise(ArgumentError, "Unsupported union between Range and #{other.class}.")
        end
    end

    def rand_from_intersection(other)
        (self & other).rand
    end
end

class Set
    def rand
        self.to_a.rand
    end
end

class String
    def indices(substr)
        ret   = []
        i
        while (i = index(substr))
            ret << i
        end
        ret.empty? ? nil : ret
    end

    def to_caml
        gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    def to_const(root=Object)
        root.const_defined?(self) ? root.const_get(self) : root.const_missing(self)
    end

    def md5
        Digest::MD5.digest(self)
    end

    def color(c)
        case c
        when :white
            self
        when :red
            "\e[1;31m#{self}\e[0m"
        when :green
            "\e[1;32m#{self}\e[0m"
        when :yellow
            "\e[1;33m#{self}\e[0m"
        else
            raise(ArgumentError, "Unhandled color #{c}.")
        end
    end
end

class Symbol
    def to_caml
        to_s.to_caml
    end

    def to_const(root=Object)
        to_s.to_const(root)
    end
end
