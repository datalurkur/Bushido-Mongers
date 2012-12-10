class Array
    def rand()
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
    def rand_key()
        self.keys.rand
    end
end

class Range
    def &(other)
        self.to_a & other.to_a
    end

    def rand_from_intersection(other)
        (self & other).rand
    end
end

class Set
    def rand()
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

    def to_const
        Object.const_defined?(self) ? Object.const_get(self) : Object.const_missing(self)
    end
end

class Symbol
    def to_caml
        to_s.to_caml
    end

    def to_const
        to_s.to_const
    end
end
