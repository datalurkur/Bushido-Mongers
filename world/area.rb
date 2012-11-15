require 'world/region_container'
require 'world/room'

class Area < RegionContainer
    def initialize(name,size)
        super(name,size)
    end

    def self.test_area
        # [a]
        #  |
        # [b]-[c]
        #  |   |
        # [d]-[e]-[f]
        #      |
        #     [g]
        #      |
        #     [h]

        area = Area.new("Test Area", 5)

        area.set_region(0,4,Room.new(:a))
        area.set_region(0,3,Room.new(:b))
        area.set_region(1,3,Room.new(:c))
        area.set_region(0,2,Room.new(:d))
        area.set_region(1,2,Room.new(:e))
        area.set_region(2,2,Room.new(:f))
        area.set_region(1,1,Room.new(:g))
        area.set_region(1,0,Room.new(:h))
        area.connect_regions(:a,:b)
        area.connect_regions(:b,:c)
        area.connect_regions(:b,:d)
        area.connect_regions(:c,:e)
        area.connect_regions(:d,:e)
        area.connect_regions(:e,:f)
        area.connect_regions(:e,:g)
        area.connect_regions(:h,:g)

        area
    end
end
