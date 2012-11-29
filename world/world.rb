require 'util/basic'
require 'world/room'
require 'graphics/png'

class World < Area
    def initialize(name, size, max_depth)
        super(name, size, max_depth)
    end

    def starting_locations
        @starting_locations ||= []
    end

    def add_starting_location(location)
        starting_locations << location
    end

    def random_starting_location
        starting_locations.rand
    end

    def print_map(filename, cell_size=20, corridor_size=4, color=:white)
        depth_powers   = (0..@depth-1).collect { |n| @size ** n }.reverse
        cells_per_side = depth_powers.first
        png_size       = cell_size * cells_per_side
        cell_sizes     = depth_powers.reverse.collect { |p| png_size / p }
        Log.debug("Printing a map of the world with cell size #{cell_size}, size/depth of #{@size}/#{@depth} (#{cells_per_side} cells per side), and a png size of #{png_size}")
        Log.debug("Preliminary depth power computation: #{depth_powers.inspect}")
        Log.debug("Preliminary png cell size computation: #{cell_sizes.inspect}")
        png = DerpyPNG.new(png_size, png_size)

        leaves.each do |leaf|
            leaf_coords = leaf.get_full_coordinates
            Log.debug("Writing data for #{leaf.name} at #{leaf_coords.inspect}")

            # Compute the coordinates of this leaf
            png_coords  = [0,0]
            leaf_coords.each_with_index do |c,i|
                Log.debug("\tMultiplying coordinates #{c.inspect} by #{depth_powers[i]} and cell size #{cell_size}")
                png_coords[0] += (c[0] * depth_powers[i+1] * cell_size)
                png_coords[1] += (c[1] * depth_powers[i+1] * cell_size)
            end
            Log.debug("\tPNG coordinates computed to be #{png_coords.inspect}")

            # Compute the size of this leaf
            local_cell_size = cell_sizes[leaf_coords.size]
            png_room_size   = local_cell_size - (corridor_size * 2)
            Log.debug("\tPNG Cell/Room size computed to be #{local_cell_size}/#{png_room_size}")

            png.fill_box(png_coords.x + corridor_size, png_coords.y + corridor_size, png_room_size, png_room_size, color)

            Log.debug("\tDrawing corridors")
            leaf.connected_directions.each do |dir|
                other = leaf.connected_leaf(dir)
                other_coords = other.get_full_coordinates
                Log.debug("\t\tCorridor to the #{dir} is connected to #{other.name}")

                corridor_offset = [0,0]
                shift_cell_size = local_cell_size

                if other_coords.size > leaf_coords.size
                    # This leaf is higher than its connection in the heirarchy, shift the hallway in the appropriate direction
                    (leaf_coords.size...other_coords.size).each do |i|
                        diff_coords    = other_coords[i]
                        diff_cell_size = cell_sizes[i+1]
                        Log.debug("\t\tShifting coordinates by #{diff_coords.inspect} * #{diff_cell_size}")

                        case dir
                        when :north, :south
                            corridor_offset[0] += (diff_coords[0] * diff_cell_size)
                        when :east,  :west
                            corridor_offset[1] += (diff_coords[1] * diff_cell_size)
                        end
                    end
                    shift_cell_size = cell_sizes[other_coords.size]
                end

                half_shift = ((shift_cell_size - corridor_size) / 2)
                edge_shift = (local_cell_size - corridor_size)

                case dir
                when :north, :south
                     corridor_offset[0] += half_shift
                    (corridor_offset[1] += edge_shift) if (dir == :north)
                when :east,  :west
                    (corridor_offset[0] += edge_shift) if (dir == :east)
                     corridor_offset[1] += half_shift
                end
                Log.debug("\t\tOffset found to be #{corridor_offset.inspect}")

                png.fill_box(png_coords.x + corridor_offset.x, png_coords.y + corridor_offset.y, corridor_size, corridor_size, color)
            end
        end

        png.save(filename)
    end

    def self.test_world
        # d---c
        #     |
        # a---b

        a = Room.new("a")
        a.connect_to(:east)

        b = Room.new("b")
        b.connect_to(:west)
        b.connect_to(:north)

        c = Room.new("c")
        c.connect_to(:south)
        c.connect_to(:west)

        d = Room.new("d")
        d.connect_to(:east)

        world = World.new("Test World", 2, 2)
        world.set_zone(0,0,a)
        world.set_zone(1,0,b)
        world.set_zone(1,1,c)
        world.set_zone(0,1,d)

        world.add_starting_location(d.get_full_coordinates)
        world.check_consistency
        world
    end

    def self.test_world_2
        c11_01 = Room.new("c11_01")
        c11_01.connect_to(:north)

        c11 = Area.new("c11", 2, 2)
        c11.set_zone(0,1,c11_01)

        b00 = Room.new("b00")
        b00.connect_to(:west)

        b10 = Room.new("b10")
        b10.connect_to(:south)

        b01 = Room.new("b01")

        d11 = Room.new("d11")
        d11.connect_to(:north)

        a = Room.new("a")
        a.connect_to(:east)
        a.connect_to(:south)

        b = Area.new("b", 2, 2)
        b.set_zone(0,0,b00)
        b.set_zone(1,0,b10)
        b.set_zone(0,1,b01)

        c = Area.new("c", 2, 3)
        c.set_zone(1,1,c11)

        d = Area.new("d", 2, 2)
        d.set_zone(1,1,d11)

        world = World.new("world", 2, 4)
        world.set_zone(0,1,a)
        world.set_zone(1,1,b)
        world.set_zone(0,0,c)
        world.set_zone(1,0,d)

        world.add_starting_location(c11_01.get_full_coordinates)
        world.check_consistency
        world
    end
end
