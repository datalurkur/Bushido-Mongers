require 'world/region_container'

class World < RegionContainer
    def initialize(size)
        super("World", size)
    end

    def self.test_world
        world = World.new(1)
        world.add_region(0,0,Zone.test_zone)
    end
end
