require './util/math'
require './util/log'
require './words/words'

class Zone
    # Create zones given a parent (nil for the root zone) and depth information.
    class << self
        # Returns args used to populate gen_area_name, Area.new and Room.new.
        def create(core, parent, depth)
            args = if parent
                # Inherit a keyword from the parent.
                #Log.debug(parent.type)
                #parent_list = core.db.info_for(parent.type, :keywords)
                #Log.debug(["Zone.create", parent.type, parent_list])

                { :type => find_child(core.db, parent, depth),
                  :inherited_keywords => []
                }
            else
                { :type => find_random(core.db, depth) }
            end
            #Log.debug("found #{args[:inherited_keywords].inspect}!") if args[:inherited_keywords]

            args[:depth]    = depth
            args[:zone]     = core.db.create(core, args[:type], args)
            args[:keywords] = core.db.info_for(args[:type], :keywords)

            args.delete(:inherited_keywords) # Shouldn't need this again.
            return args
        end

        private
        def zones_of_depth(db, depth, list = db.types_of(:zone))
            list.select do |zone|
                db.info_for(zone, :depth_range).include?(depth)
            end
        end

        def find_child(db, parent, depth)
            potential_zones = zones_of_depth(db, depth, db.info_for(parent.type, :child_zones))

            if potential_zones.empty?
                potential_zones = zones_of_depth(db, depth)
            end

            type = potential_zones.rand
            raise "Found invalid child zone type #{type} in #{parent.type}!\n" unless db[type]
            return type
        end

        def find_random(db, depth)
            return zones_of_depth(db, depth).rand
        end
    end

    public
    class << self
        def direction_opposite(direction)
            case direction
            when :north; :south
            when :south; :north
            when :east;  :west
            when :west;  :east
            end
        end
    end

    attr_reader :name, :offset
    def initialize(name)
        @name = name
    end

    def set_parent(parent, offset)
        @parent = parent
        @offset = offset
    end

    def get_full_coordinates
        if @parent
            @parent.get_full_coordinates + [@offset]
        else
            []
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
        Log.debug("(UP) Finding neighbor leaves to the #{dir} of #{upwards_history.last.inspect} in #{@name}", 5)
        adjacent_coords = case dir
        when :north; [upwards_history.last.x,   upwards_history.last.y+1]
        when :south; [upwards_history.last.x,   upwards_history.last.y-1]
        when :east;  [upwards_history.last.x+1, upwards_history.last.y  ]
        when :west;  [upwards_history.last.x-1, upwards_history.last.y  ]
        end
        Log.debug("\t#{adjacent_coords.inspect}", 7)

        if adjacent_coords.x < 0 || adjacent_coords.x >= @size || adjacent_coords.y < 0 || adjacent_coords.y >= @size
            raise "Reached the edge of the world looking for leaves in #{@name}" if @parent.nil?
            @parent.find_neighbor_leaves_upwards(dir, upwards_history + [@offset])
        else
            if has_zone?(*adjacent_coords)
                zone_at(*adjacent_coords).find_neighbor_leaves_downwards(dir, upwards_history[0...-1])
            else
                []
            end
        end
    end
end

class ZoneContainer < Zone
    attr_reader :size
    def initialize(name, size, depth)
        super(name)

        @size   = size
        @depth  = depth

        @zones       = Array.new(@size) { Array.new(@size) }
        @zonemap     = {}
    end

    def leaves
        @zones.collect do |row|
            row.collect do |zone|
                if ZoneContainer === zone
                    zone.leaves
                else
                    zone
                end
            end
        end.flatten.compact
    end

    def has_zone?(x, y)
        @zones[x][y]
    end

    def abuts_edge?(dir, coords)
        this_edge = case dir
        when :north
            coords.last.y == (@size - 1)
        when :south
            coords.last.y == 0
        when :east
            coords.last.x == (@size - 1)
        when :west
            coords.last.x == 0
        end

        if this_edge && @parent
            @parent.abuts_edge?(dir, coords[0...-1])
        elsif this_edge
            true
        else
            false
        end
    end

    def depth
        @depth
    end

    def get_zone(positions)
        p = positions.first
        subzone = zone_at(p.x, p.y)
        if positions.size == 1
            raise "Found a non-leaf zone" unless ZoneLeaf === subzone
            subzone
        else
            subzone.get_zone(positions[1..-1])
        end
    end

    def zone_at(x, y)
        raise "No zone at #{[x,y].inspect} in #{@name}" if @zones[x][y].nil?
        @zones[x][y]
    end

    def set_zone(x, y, zone)
        raise "Zone at #{[x,y].inspect} being overwritten in #{@name}" unless @zones[x][y].nil?
        @zones[x][y]        = zone
        @zonemap[zone.name] = zone
        zone.set_parent(self, [x,y])
    end

    # TODO - Remove this method, hashing zones by name is dangerous
    def zone_location(zone_name)
        raise "No zone #{zone_name} found in #{@name}" unless @zonemap.has_key?(zone_name)
        @zonemap[zone_name].offset
    end

    # TODO - Remove this method, hashing zones by name is dangerous
    def zone_named(zone_name)
        raise "No zone #{zone_name} found in #{@name}" unless @zonemap.has_key?(zone_name)
        @zonemap[zone_name]
    end

    # TODO - Remove this method, hashing zones by name is dangerous
    def connect_zones(zone_a, zone_b)
        coords_a = zone_location(zone_a)
        coords_b = zone_location(zone_b)
        dirs     = directions_between(coords_a, coords_b)
        zone_named(zone_a).connect_to(dirs[0])
        zone_named(zone_b).connect_to(dirs[1])
    end

    def find_neighbor_leaves_downwards(dir, upwards_history)
        Log.debug("(DOWN) Traversing down with history #{upwards_history.inspect}", 5)
        # We want to traverse downwards respective to the coordinates we used when traversing upwards
        traversal_range = unless upwards_history.empty?
            last_traversal = upwards_history.last
            Log.debug("(Last traversal: #{last_traversal.inspect})", 5)
            case dir
            when :north, :south; [last_traversal.x]
            when :east,  :west;  [last_traversal.y]
            end
        else
            (0...@size)
        end

        Log.debug("Finding neighbor leaves on the #{Zone.direction_opposite(dir)} side of #{@name} on the range #{traversal_range.inspect}", 5)

        traversal_range.collect do |dim|
            coords = case dir
            when :north; [dim,     0      ]
            when :south; [dim,     @size-1]
            when :east;  [0,       dim    ]
            when :west;  [@size-1, dim    ]
            end

            Log.debug("\tChecking #{coords.inspect}", 5)
            if has_zone?(*coords)
                Log.debug("Zone found!", 5)
                zone_at(*coords).find_neighbor_leaves_downwards(dir, upwards_history[0...-1])
            else
                Log.debug("Zone missing", 5)
                []
            end
        end.flatten
    end

    def check_consistency
        Log.debug("Checking the consistency of #{@name}", 3)
        (0...@size).each do |x|
            (0...@size).each do |y|
                if has_zone?(x,y)
                    zone_at(x,y).check_consistency
                end
            end
        end
    end
end

class ZoneLeaf < Zone
    def initialize(name)
        super(name)

        @connections = {}
    end

    def depth
        @parent.depth - 1
    end

    def find_neighbor_leaves_downwards(dir, upwards_history)
        Log.debug("Leaf found at #{get_full_coordinates.inspect}", 5)
        [self]
    end

    def abuts_edge?(dir)
        @parent.abuts_edge?(dir, get_full_coordinates)
    end

    def connect_to(direction)
        @connections[direction] = true
    end

    def remove_connection(direction)
        @connections[direction] = false
    end

    def connected_to?(direction)
        @connections[direction]
    end

    def connected_directions
        @connections.keys.select { |dir| @connections[dir] }
    end

    def connectable_leaves(direction)
        @parent.find_neighbor_leaves_upwards(direction, [@offset])
    end

    def connected_leaf(direction)
        Log.debug("Finding leaf connected to the #{direction} of #{@name} (#{@offset.inspect})", 5)
        raise "Can't traverse to the #{direction} from #{@name}" unless connected_to?(direction)
        connected_leaves = connectable_leaves(direction).select { |leaf| leaf.connected_to?(Zone.direction_opposite(direction)) }
        if connected_leaves.size == 0
            raise "Could not find a leaf connected to the #{direction} of #{@name}"
        elsif connected_leaves.size > 1
            raise "Found multiple connections for a single leaf"
        else
            connected_leaves.first
        end
    end

    def check_consistency
        @connections.keys.select { |d| @connections[d] }.each do |dir|
            other = connected_leaf(dir)
            unless other.connected_leaf(Zone.direction_opposite(dir)) == self
                raise "Zone connection consistency check failed - #{@name} does not connect uniquely to the #{dir} with #{other.name}"
            end
        end
    end
end
