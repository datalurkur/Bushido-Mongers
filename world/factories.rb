require 'world/world'
require 'math/noisemap'

class WorldFactory
class << self
    def generate(size, depth, config={})
        # TODO - Make the seeding a bit more intelligent
        #seed = Time.now.to_i
        seed = 1354174054
        Log.debug("Seeding world with #{seed}")
        srand(seed)

        # TODO - Generate a cool name for the world
        world_name = "Default World Name"
        world = World.new(world_name, size, depth)
        config[:openness]      ||= 0.3
        config[:connectedness] ||= 0.3
        populate_area(world, config[:openness], config[:connectedness])
        world
    end

    # Based
    def generate_area(size, depth, parent_area)
        # TODO - This is where the logic for selecting zone templates and applying them comes into play

        # For now, just create a generic area or room randomly
        name = "#{parent_area.name}-#{rand(1000)}"
        area = if (depth < 2) || (rand() < 0.5)
            Log.debug("Generating room #{name}", 5)
            Room.new(name)
        else
            Log.debug("Generating area #{name} of size #{size} and depth #{depth}", 5)
            Area.new(name, size, depth)
        end

        if Area === area
            # These will almost certainly be set by the zone template
            openness      = 0.5
            connectedness = 0.5
            populate_area(area, openness, connectedness, parent_area)
        end

        area
    end

    def populate_area(area, openness, connectedness, parent_area=nil)
        Log.debug("Populating area #{area.name}", 5)
        noise_size = 3*area.size
        noisemap = NoiseMap.new(noise_size)
        noisemap.populate
        #noisemap.save_to_png("#{area.name}.png")

        (0...area.size).each do |x|
            (0...area.size).each do |y|
                Log.debug("Filling #{[x,y].inspect}", 5)
                iX = 3*x + 1.0
                iY = 3*y + 1.0
                if noisemap.get_scaled(iX, iY, 0.0, 1.0) > openness
                    # Create a zone at these coordinates
                    subarea = generate_area(area.size, area.depth - 1, area)
                    area.set_zone(x, y, subarea)
                    Log.debug("Set subarea #{subarea.name} with coords #{subarea.get_full_coordinates.inspect}", 7)

                    # Potentially generate connectivity information
                    if Room === subarea
                        if noisemap.get_scaled(iX-1, iY,   0.0, 1.0) > connectedness
                            Log.debug("Connecting room to the west", 9)
                            subarea.connect_to(:west)
                        end
                        if noisemap.get_scaled(iX+1, iY,   0.0, 1.0) > connectedness
                            Log.debug("Connecting room to the east", 9)
                            subarea.connect_to(:east)
                        end
                        if noisemap.get_scaled(iX,   iY-1, 0.0, 1.0) > connectedness
                            Log.debug("Connecting room to the south", 9)
                            subarea.connect_to(:south)
                        end
                        if noisemap.get_scaled(iX,   iY+1, 0.0, 1.0) > connectedness
                            Log.debug("Connecting room to the north", 9)
                            subarea.connect_to(:north)
                        end
                    end
                end
            end
        end

        Log.debug("Cleaning up connections", 5)
        if parent_area.nil?
            # Eliminate excess / broken connections
            area.leaves.each do |leaf|
                Log.debug("Cleaning connections for #{leaf.name} (#{leaf.get_full_coordinates.inspect})", 5)
                leaf.connected_directions.each do |dir|
                    Log.debug("\tExamining #{dir} connection for #{leaf.name}", 7)

                    # Just eliminate zone connections at the edge of the world
                    if leaf.abuts_edge?(dir)
                        Log.debug("\tRemoving #{dir} connection from #{leaf.name}", 7)
                        leaf.remove_connection(dir)
                        next
                    end

                    # For a given direction, find all possible leaves that can connect to it, select one at random, and forcibly disconnect the rest
                    others = leaf.connectable_leaves(dir).select do |other|
                        other.connected_to?(Zone.direction_opposite(dir))
                    end
                    Log.debug("\t#{others.size} potential connections", 7)

                    if others.empty?
                        # No zones to connect to, remove this connection
                        leaf.remove_connection(dir)
                        next
                    else
                        chosen = others.rand
                        Log.debug("\t#{chosen.name} chosen", 7)
                        (others - [chosen]).each do |other|
                            Log.debug("\t\tRemoving connection to #{other.name}", 7)
                            other.remove_connection(Zone.direction_opposite(dir))
                        end
                    end
                end
            end
        end
    end
end
end
