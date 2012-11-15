require 'world/region_container'
require 'world/zone'

class World < RegionContainer
    def initialize(size)
        super("World", size)
    end

    def self.test_world
        world = World.new(1)
        world.set_region(0,0,Zone.test_zone)
        world
    end
end
