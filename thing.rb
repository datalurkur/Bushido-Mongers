class Thing
    class << self
        def describe(name, attrs={})
            types[name] = attrs
        end

        def types; @types ||= {}; end
    end
end

Thing.describe("Dango", {
    :keywords => [:food],
    :weight   => 0.5,
    :size     => :small,
    :cost     => 2
})
