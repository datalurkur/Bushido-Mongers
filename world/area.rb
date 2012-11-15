require 'world/region_container'

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

        add_region(0,4,Room.new(:a))
        add_region(0,3,Room.new(:b))
        add_region(1,3,Room.new(:c))
        add_region(0,2,Room.new(:d))
        add_region(1,2,Room.new(:e))
        add_region(2,2,Room.new(:f))
        add_region(1,1,Room.new(:g))
        add_region(1,0,Room.new(:h))
        connect_regions(:a,:b)
        connect_regions(:b,:c)
        connect_regions(:b,:d)
        connect_regions(:c,:e)
        connect_regions(:d,:e)
        connect_regions(:e,:f)
        connect_regions(:e,:g)
        connect_regions(:h,:g)
    end
end
