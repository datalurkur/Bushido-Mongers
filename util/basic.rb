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

class Symbol
    def to_title
        self.to_s.gsub(/_/, ' ').gsub(/(^| )(.)/) { "#{$1}#{$2.upcase}" }
    end
end

class Set
    def rand()
        self.to_a.rand
    end
end

class String
    # For now, just capitalize the beginning.
    def sentence
        self.gsub(/^(\w)/) { $1.upcase }
    end
end
