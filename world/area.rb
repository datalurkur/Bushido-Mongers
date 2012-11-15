require 'world/region_container'

class Area < RegionContainer
    def initialize(name,size)
        super(name,size)
    end

    def self.test_area
        # [0]
        #  |
        # [1]-[2]
        #  |   |
        # [3]-[4]-[5]
        #      |
        #     [6]
        #      |
        #     [7]

        area = Area.new("Test Area", 5)

        add_region(0,4,Room.new(0))
        add_region(0,3,Room.new(1))
        add_region(1,3,Room.new(2))
        add_region(0,2,Room.new(3))
        add_region(1,2,Room.new(4))
        add_region(2,2,Room.new(5))
        add_region(1,1,Room.new(6))
        add_region(1,0,Room.new(7))
        connect_regions([0,4],[0,3])
        connect_regions([0,3],[1,3])
        connect_regions([0,3],[0,2])
        connect_regions([1,3],[1,2])
        connect_regions([0,2],[1,2])
        connect_regions([1,2],[2,2])
        connect_regions([1,2],[1,1])
        connect_regions([1,1],[1,0])
    end
end
