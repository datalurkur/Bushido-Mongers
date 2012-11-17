require 'world/zone'

class World < ZoneContainer
    def initialize(name, max_depth,size)
        super(name, size, max_depth)
    end

    def self.test_world
        # d---c
        #     |
        # a---b

        a = ZoneLeaf.new("a")
        a.connect_to(:east)

        b = ZoneLeaf.new("b")
        b.connect_to(:west)
        b.connect_to(:north)

        c = ZoneLeaf.new("c")
        c.connect_to(:south)
        c.connect_to(:west)

        d = ZoneLeaf.new("d")
        d.connect_to(:east)

        world = World.new("Test World", 2, 3)
        world.set_zone(0,0,a)
        world.set_zone(1,0,b)
        world.set_zone(0,1,c)
        world.set_zone(1,1,d)
        world
    end
end
