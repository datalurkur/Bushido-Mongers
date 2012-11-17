require 'util/math'
require 'util/log'

# FIXME - Better separate zone and leaf functionality
class Zone
    attr_reader :name, :offset
    def initialize(name)
        @name = name
    end

    def set_parent(parent, offset)
        @parent = parent
        @offset = offset
    end

    def direction_opposite(direction)
        case direction
        when :north; :south
        when :south; :north
        when :east;  :west
        when :west;  :east
        end
    end

    # Returns an array containin [direction from a to b, direction from b to a]
    def directions_between(coords_a, coords_b)
        diff = [coords_a.x - coords_b.x, coords_a.y - coords_b.y]
        raise "Coordinates #{coords_a.inspect} and #{coords_b.inspect} are not adjacent" if (diff[0].abs + diff[1].abs) != 1
        if    diff[0] > 0 
            [:west, :east]
        elsif diff[0] < 0
            [:east, :west]
        elsif diff[1] > 0
            [:south, :north]
        else
            [:north, :south]
        end
    end

    # Traverse up the tree until we find a zone that abuts the edge we're concerned with
    # upwards_history is a list of the offsets used to walk upwards to this part of the tree, with the original leaf at index 0
    # dir is the direction we want to traverse from that leaf to arrive at the destination leaf
    def find_neighbor_leaves_upwards(dir, upwards_history)
        Log.debug("(UP) Finding neighbor leaves to the #{dir} of #{upwards_history.last.inspect} in #{@name}",5)
        adjacent_coords = case dir
        when :north; [upwards_history.last.x,   upwards_history.last.y+1]
        when :south; [upwards_history.last.x,   upwards_history.last.y-1]
        when :east;  [upwards_history.last.x+1, upwards_history.last.y  ]
        when :west;  [upwards_history.last.x-1, upwards_history.last.y  ]
        end
        Log.debug("\t#{adjacent_coords.inspect}",7)

        if adjacent_coords.x < 0 || adjacent_coords.x >= @size || adjacent_coords.y < 0 || adjacent_coords.y >= @size
            raise "Reached the edge of the world looking for leaves in #{@name}" if @parent.nil?
            @parent.find_neighbor_leaves_upwards(dir, upwards_history + [@offset])
        else
            get_zone(*adjacent_coords).find_neighbor_leaves_downwards(dir, upwards_history, 1)
        end
    end


end

class ZoneContainer < Zone
    def initialize(name, size=nil, depth=nil)
        super(name)

        @size   = size  || 1
        @depth  = depth || 1

        @zones       = Array.new(@size) { Array.new(@size) }
        @zonemap     = {}
    end

    def has_zone?(x, y)
        @zones[x][y]
    end

    def get_zone(x, y)
        raise "No zone at #{[x,y].inspect} in #{@name}" if @zones[x][y].nil?
        @zones[x][y]
    end

    def set_zone(x, y, zone)
        raise "Zone at #{[x,y].inspect} being overwritten in #{@name}" unless @zones[x][y].nil?
        @zones[x][y]        = zone
        @zonemap[zone.name] = zone
        zone.set_parent(self, [x,y])
    end

    def zone_location(zone_name)
        raise "No zone #{zone_name} found in #{@name}" unless @zonemap.has_key?(zone_name)
        @zonemap[zone_name].offset
    end

    def zone_named(zone_name)
        raise "No zone #{zone_name} found in #{@name}" unless @zonemap.has_key?(zone_name)
        @zonemap[zone_name]
    end

    # FIXME - This needs to be expanded upon to allow zones to be connected to zones from other parents
    def connect_zones(zone_a, zone_b)
        coords_a = zone_location(zone_a)
        coords_b = zone_location(zone_b)
        dirs     = directions_between(coords_a, coords_b)
        zone_named(zone_a).connect_to(dirs[0])
        zone_named(zone_b).connect_to(dirs[1])
    end

    def find_neighbor_leaves_downwards(dir, upwards_history, depth)
        # We want to traverse downwards respective to the coordinates we used when traversing upwards
        traversal_range = if depth < upwards_history.size
            last_traversal = upwards_history[upwards_history.size - depth]
            case dir
            when :north, :south; [last_traversal.x]
            when :east,  :west;  [last_traversal.y]
            end
        else
            (0...@size)
        end

        Log.debug("(DOWN) Finding neighbor leaves on the #{direction_opposite(dir)} side of #{@name} on the range #{traversal_range.inspect}",5)

        traversal_range.collect do |dim|
            coords = case dir
            when :north; [dim,     0      ]
            when :south; [dim,     @size-1]
            when :east;  [0,       dim    ]
            when :west;  [@size-1, dim    ]
            end

            has_zone?(*coords) ?
                get_zone(*coords).find_neighbor_leaves_downwards(dir, upwards_history, depth+1):
                []
        end.flatten
    end
end

class ZoneLeaf < Zone
    def initialize(name)
        super(name)

        @connections = {}
    end

    def find_neighbor_leaves_downwards(dir, upwards_history, depth)
        [self]
    end

    def connect_to(direction)
        @connections[direction] = true
    end

    def connected_to?(direction)
        @connections[direction]
    end

    def connectable_leaves(direction)
        @parent.find_neighbor_leaves_upwards(direction, [@offset])
    end

    def connected_leaf(direction)
        Log.debug("Finding leaf connected to the #{direction} of #{@name} (#{@offset.inspect})",5)
        raise "Can't traverse to the #{direction} from #{@name}" unless connected_to?(direction)
        connected_leaves = connectable_leaves(direction).select { |leaf| leaf.connected_to?(direction_opposite(direction)) }
        if connected_leaves.size == 0
            raise "Could not find a leaf connected to the #{direction} of #{@name}"
        elsif connected_leaves.size > 1
            raise "Found multiple connections for a single leaf"
        else
            connected_leaves.first
        end
    end
end
