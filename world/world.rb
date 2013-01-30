require './util/basic'
require './util/exceptions'
require './world/room'
require './graphics/png'

class World < Area
    def finalize
        # Cache room adjacency to avoid lookups
        leaves.each do |leaf|
            leaf.resolve_connections
        end
    end

    # Also see the recursive method Area::add_starting_location.
    def starting_locations
        @starting_locations ||= []
    end

    def random_starting_location
        raise(StateError, "No starting locations!") if starting_locations.empty?
        starting_locations.rand
    end

    def get_map(colored_rooms={}, cell_size=30, corridor_size=6, default_color=:white)
        depth_powers   = (0..@depth-1).collect { |n| @size ** n }.reverse
        cells_per_side = depth_powers.first
        png_size       = cell_size * cells_per_side
        cell_sizes     = depth_powers.reverse.collect { |p| png_size / p }
        Log.debug("Preliminary depth power computation: #{depth_powers.inspect}", 5)
        Log.debug("Preliminary png cell size computation: #{cell_sizes.inspect}", 5)
        png = DerpyPNG.new(png_size, png_size)

        leaves.each do |leaf|
            leaf_coords = leaf.get_full_coordinates
            Log.debug("Writing data for #{leaf.name} at #{leaf_coords.inspect}", 7)

            # Compute the coordinates of this leaf
            png_coords  = [0,png_size-1]
            leaf_coords.each_with_index do |c,i|
                Log.debug("\tMultiplying coordinates #{c.inspect} by #{depth_powers[i]} and cell size #{cell_size}", 9)
                png_coords[0] += (c[0] * depth_powers[i+1] * cell_size)
                png_coords[1] -= (c[1] * depth_powers[i+1] * cell_size)
            end
            Log.debug("\tPNG coordinates computed to be #{png_coords.inspect}", 7)

            # Compute the size of this leaf
            local_cell_size = cell_sizes[leaf_coords.size]
            png_room_size   = local_cell_size - (corridor_size * 2)
            Log.debug("\tPNG Cell/Room size computed to be #{local_cell_size}/#{png_room_size}", 7)

            room_color = colored_rooms.has_key?(leaf) ? colored_rooms[leaf] : default_color
            png.fill_box(png_coords.x + corridor_size, png_coords.y - corridor_size - png_room_size, png_room_size, png_room_size, room_color)

            Log.debug("\tDrawing corridors", 7)
            leaf.connected_directions.each do |dir|
                other = leaf.get_adjacent(dir)
                other_coords = other.get_full_coordinates
                Log.debug("\t\tCorridor to the #{dir} is connected to #{other.name}", 9)

                corridor_offset = [0,0]
                shift_cell_size = local_cell_size

                if other_coords.size > leaf_coords.size
                    # This leaf is higher than its connection in the heirarchy, shift the hallway in the appropriate direction
                    (leaf_coords.size...other_coords.size).each do |i|
                        diff_coords    = other_coords[i]
                        diff_cell_size = cell_sizes[i+1]
                        Log.debug("\t\tShifting coordinates by #{diff_coords.inspect} * #{diff_cell_size}", 9)

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
                Log.debug("\t\tOffset found to be #{corridor_offset.inspect}", 9)

                png.fill_box(png_coords.x + corridor_offset.x, png_coords.y - corridor_offset.y - corridor_size, corridor_size, corridor_size, default_color)
            end
        end

        png.get_png_data
    end
end
