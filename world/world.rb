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

    def get_room_layout(total_size, corridor_ratio)
        Log.info("Getting room layout given total size #{total_size} and corridor ratio #{corridor_ratio} (#{@depth} depths)")

        depth_powers   = (0..@depth).collect { |n| @size ** n }.reverse
        cells_per_side = depth_powers[1]
        cell_size      = total_size / cells_per_side
        corridor_size  = (cell_size * corridor_ratio).to_i
        cell_sizes     = depth_powers.reverse.collect { |p| total_size / p }

        Log.debug(["Depth powers", depth_powers, "Results in cells-pert-side and cell size #{cells_per_side} / #{cell_size}", cell_sizes])

        if corridor_size <= 0
            Log.warning("Corridors will be invisible, cell size (#{cell_size}) and corridor ratio too small")
            corridor_size = 0
        end

        room_layout    = {
            :total_size    => total_size,
            :corridor_size => corridor_size,
            :rooms         => {}
        }

        Log.info("Generating layout information for #{leaves.size} leaves")

        leaves.each do |leaf|
            leaf_data = {}

            base_coords = leaf.get_full_coordinates
            #Log.debug(["Generating room info at", base_coords])

            # Compute the position and dimension of this room
            local_cell_size = cell_sizes[base_coords.size]
            room_size       = local_cell_size - (corridor_size * 2)
            room_coords     = [0, total_size - 1]
            base_coords.each_with_index do |c,i|
                room_coords[0] += (c[0] * depth_powers[i+2] * cell_size)
                room_coords[1] -= (c[1] * depth_powers[i+2] * cell_size)
            end

            leaf_data[:room_size]   = room_size
            leaf_data[:cell_size]   = local_cell_size
            leaf_data[:room_coords] = [
                room_coords.x + corridor_size,
                room_coords.y - corridor_size - room_size
            ]
            leaf_data[:cell_coords] = [
                room_coords.x,
                room_coords.y - local_cell_size
            ]

            # Compute the positions and dimensions of the corridors
            leaf_data[:connections] = {}
            leaf.connected_directions.each do |dir|
                other           = leaf.get_adjacent(dir)
                other_coords    = other.get_full_coordinates

                if other_coords.size > @depth
                    Log.error("Cell is deeper (#{other_coords.size} / #{@depth}) than it's allowed to be!")
                end

                corridor_offset = [0,0]
                shift_cell_size = local_cell_size

                if other_coords.size > base_coords.size
                    # This leaf is higher than its connection in the heirarchy,
                    #  shift the hallway in the appropriate direction
                    (base_coords.size...other_coords.size).each do |i|
                        diff_coords    = other_coords[i]
                        diff_cell_size = cell_sizes[i+1]

                        case dir
                        when :north, :south
                            corridor_offset[0] += (diff_coords[0] * diff_cell_size)
                        when :east,  :west
                            corridor_offset[1] += (diff_coords[1] * diff_cell_size)
                        end
                    end
                    shift_cell_size = cell_sizes[other_coords.size]
                end

                half_shift = (shift_cell_size - corridor_size) / 2
                edge_shift = (local_cell_size - corridor_size)

                case dir
                when :north, :south
                     corridor_offset[0] += half_shift
                    (corridor_offset[1] += edge_shift) if (dir == :north)
                when :east,  :west
                    (corridor_offset[0] += edge_shift) if (dir == :east)
                     corridor_offset[1] += half_shift
                end

                leaf_data[:connections][dir] = {
                    :coords => [
                        room_coords.x + corridor_offset.x,
                        room_coords.y - corridor_offset.y - corridor_size
                    ],
                    :connection => other
                }
            end

            room_layout[:rooms][leaf] = leaf_data
        end

        room_layout
    end

    def get_map_layout(png_size, corridor_ratio, colored_rooms={}, default_color=:white)
        layout        = get_room_layout(png_size, corridor_ratio)
        corridor_size = layout[:corridor_size]

        png = DerpyPNG.new(png_size, png_size)

        layout[:rooms].keys.each do |room|
            room_data      = layout[:rooms][room]
            room_coords    = room_data[:room_coords]
            room_size      = room_data[:room_size]
            png_room_color = colored_rooms.has_key?(room) ? colored_rooms[room] : default_color

            png.fill_box(room_coords.x, room_coords.y, room_size, room_size, png_room_color)

            room_data[:connections].keys.each do |dir|
                coords = room_data[:connections][dir][:coords]

                png.fill_box(coords.x, coords.y, corridor_size, corridor_size, default_color)
            end
        end

        png.get_png_data
    end
end
