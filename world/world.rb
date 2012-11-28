require 'util/basic'
require 'world/room'

class World < Area
    def initialize(name, max_depth,size)
        super(name, size, max_depth)
    end

    def starting_locations
        @starting_locations ||= []
    end

    def add_starting_location(location)
        starting_locations << location
    end

    def random_starting_location
        starting_locations.rand
    end

    def self.test_world
        # d---c
        #     |
        # a---b

        a = Room.new("a")
        a.connect_to(:east)

        b = Room.new("b")
        b.connect_to(:west)
        b.connect_to(:north)

        c = Room.new("c")
        c.connect_to(:south)
        c.connect_to(:west)

        d = Room.new("d")
        d.connect_to(:east)

        world = World.new("Test World", 2, 2)
        world.set_zone(0,0,a)
        world.set_zone(1,0,b)
        world.set_zone(0,1,c)
        world.set_zone(1,1,d)

        world.add_starting_location(d.get_full_coordinates)
        world
    end
end
