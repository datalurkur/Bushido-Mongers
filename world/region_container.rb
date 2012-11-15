class RegionContainer
    attr_reader :name

    def initialize(name, size)
        @name = name
        @size = size
        @regions     = Array.new(size) { Array.new(size) }
        @connections = Array.new(size) { Array.new(size) }
    end

    def region_exists?(x,y); @regions[x][y]; end
    def region_connected?(x,y,dir)
        @connections[x][y]
    end

    def regions_adjacent?(c1, c2)
        d = [
            (c1[0] - c2[0]).abs,
            (c1[1] - c2[1]).abs
        ]

        (d[0] + d[1] == 1)
    end

    def regions_connected?(c1, c2)
        dirs = direction_to(c1,c2)
        region_connected?(c1[0], c1[1], dirs[0]) && region_connected?(c2[0], c2[1], dirs[1])
    end

    def direction_to(c1, c2)
        dx = (c1[0] - c2[0])
        case dx
        when  1: return [:west, :east]
        when -1: return [:east, :west]
        when  0
            dy = (c1[1] - c2[1])
            case dy
            when  1: return [:north, :south]
            when -1: return [:south, :north]
            else
                raise "Regions are not adjacent, validate 'regions_adjacent?(...)'"
            end
        end
    end

    def set_region(x,y,region)
        raise "Attempting to overwrite region at #{[x,y].inspect}" if region_exists?(x,y)
        @regions[x][y]     = region
        @connections[x][y] = {}
    end

    def connect_region(x,y,direction)
        raise "No existing region at #{[x,y].inspect}" unless region_exists?(x,y)
        @connections[x][y][direction = true
    end

    def connect_regions(c1, c2)
        [c1,c2].each { |coords| raise "No existing region at #{coords.inspect}" unless region_exists?(*coords) }
        raise "Regions are not adjacent, and portals are not yet implemented" unless regions_adjacent?(c1, c2)
        dirs = direction_to(c1, c2)
        connect_region(c1,dirs[0])
        connect_region(c2,dirs[1])
    end
end
