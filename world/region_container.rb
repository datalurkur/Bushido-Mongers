class RegionContainer
    attr_reader :name

    def initialize(name, size)
        @name = name
        @size = size
        @lookup      = {}
        @regions     = Array.new(size) { Array.new(size) }
        @connections = Array.new(size) { Array.new(size) }
    end

    def location_of(region)
        raise "Region #{region} does not exist" unless @lookup.has_key?(region)
        @lookup[region]
    end
    def region_at?(x,y); @regions[x][y]; end
    def region_exists?(region); @lookup.has_key?(region); end
    def region_connected?(region,dir)
        x,y = location_of(region)
        @connections[x][y]
    end

    def regions_adjacent?(c1, c2)
        d = [
            (c1[0] - c2[0]).abs,
            (c1[1] - c2[1]).abs
        ]

        (d[0] + d[1] == 1)
    end

    def regions_connected?(r1, r2)
        c1 = location_of(r1)
        c2 = location_of(r2)
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
        raise "Attempting to overwrite region at #{[x,y].inspect}" if region_at?(x,y)
        raise "Region already registered to #{location_of(region)}" if region_exists?(region)
        @lookup[region.name] = [x,y]
        @regions[x][y]       = region
        @connections[x][y]   = {}
    end

    def connect_region(x,y,direction)
        raise "No existing region at #{[x,y].inspect}" unless region_at?(x,y)
        @connections[x][y][direction] = true
    end

    def connect_regions(r1, r2)
        c1 = location_of(r1)
        c2 = location_of(r2)
        connect_coords(c1,c2)
    end

    def connect_coords(c1, c2)
        [c1,c2].each { |coords| raise "No existing region at #{coords.inspect}" unless region_at?(*coords) }
        raise "Regions are not adjacent, and portals are not yet implemented" unless regions_adjacent?(c1, c2)
        dirs = direction_to(c1, c2)
        connect_region(c1[0], c1[1], dirs[0])
        connect_region(c2[0], c2[1], dirs[1])
    end
end
