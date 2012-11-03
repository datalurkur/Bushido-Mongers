class Array
    def select_random
        self[rand(self.size)]
    end

    def has_elements_in_common?(other)
        ((self-other).size != self.size)
    end

    def union(other)
        self.select { |i| other.include?(i) }
    end
end

class Symbol
    def <=>(other)
        self.to_s <=> other.to_s
    end

    def proper_name
        self.to_s.gsub(/(?:^|_)./) { |i| i.upcase }.gsub(/_/, ' ')
    end
end

class TypedConstructor
    class << self
        attr_reader :types
        def describe(hash)
            @types ||= []
            @types << hash
        end

        def list_types
            @types.collect { |i| i[:name] }
        end

        def select_type(name, &filter_block)
            if name
                @types.select { |i| i[:name] == name }
            else
                @types.select do |i|
                    results = i.collect do |k,v|
                        yield(k,v)
                    end
                    results.compact.inject(true) { |j,k| k ? j : false }
                end
            end.select_random
        end

        def random_type
            (raise "No types for #{self.class}") if @types.empty?
            @types[rand(@types.size)]
        end
    end

    attr_reader :name, :description
    def initialize(name=nil, &filter_block)
        type = self.class.select_type(name, &filter_block)
        unless type
            debug("#{self.class} type #{name.inspect} not found")
            type = self.class.random_type
        end

        @name        = type[:name]
        @description = type[:description]

        type
    end
end
