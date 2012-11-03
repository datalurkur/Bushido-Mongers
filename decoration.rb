require 'util'

class Decoration < TypedConstructor
    class << self
        def sizes; [:small,:normal,:large]; end
        def random_size; self.sizes[rand(self.sizes.size)]; end
        def compatible_sizes?(filter, type)
            return true if filter.nil?
            return true if filter == :any || type == :any
            if Array === filter
                (Array === type) ? filter.has_elements.in_common?(type) : filter.include?(type)
            else
                (Array === type) ? type.include?(filter) : filter == type
            end
        end
        def actual_size(filter, type)
            if filter.nil? || filter == :any
                (Array === type) ? type.select_random : type
            else
                filter
            end
        end
        def size_name(size)
            unless size == :normal
                "#{size.proper_name} "
            else
                ""
            end
        end
    end

    attr_reader :size
    def initialize(args={})
        raise "Please god no, don't select a range of sizes" if Array === args[:size]
        type = super() do |k,v|
            (k == :size) ? Decoration.compatible_sizes?(args[:size], v) : nil
        end
        @size = Decoration.actual_size(args[:size], type[:size])
        @name = "#{Decoration.size_name(@size)}#{type[:name]}"

        self
    end
end

Decoration.describe({
    :name        => "Buddha Statue",
    :description => "a golden statue of a smiling, round-bellied man",
    :size        => :any
})

Decoration.describe({
    :name        => "Gong",
    :description => "a large metal instrument which resonates with energy",
    :size        => :large
})

Decoration.describe({
    :name        => "Lion Gargoyle",
    :description => "a stone quadruped which watches vigilantly over the castle",
    :size        => :normal
})

Decoration.describe({
    :name        => "Paper Lantern",
    :description => "a small, spherical lamp that glows faintly",
    :size        => :small
})

Decoration.describe({
    :name        => "Carved Stone Pillar",
    :description => "a sturdy stone column that has withstood the test of time",
    :size        => :normal
})

Decoration.describe({
    :name        => "Rice Paper Divider",
    :description => "a thin wall used for dressing and undressing",
    :size        => :normal
})

Decoration.describe({
    :name        => "Wooden Crate",
    :description => "a box, probably left behind by some disgruntled workmen",
    :size        => :any
})

Decoration.describe({
    :name        => "Sword Rack",
    :description => "a slim, sturdy rack used to hold swords...swords which are mysteriously absent",
    :size        => :normal
})
