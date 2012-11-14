class Thing
    class << self
        def describe(name, attrs={})
            types[name] = attrs
        end

        def types; @types ||= {}; end
        def type_described?(type); types.has_key?(type); end

        def attrs(type)
            types[type]
        end

        def create(type)
            raise "Thing #{type} has not been described" unless type_described?(type)
            Thing.new(type, attrs(type))
        end
    end
end

Thing.describe("Dango", {
    :keywords => [:food],
    :weight   => 0.5,
    :size     => :small,
    :cost     => 2
})
