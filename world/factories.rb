require './world/world'
require './lib/noisemap'
require './util/timer'

class WorldFactory
class << self
    def generate(core, config={})
        set_defaults(config)
        Log.info(["Generating world with config", config])

        size, depth = config[:world_size], config[:world_depth]

        params = Zone.get_params(core, :depth => depth)

        world_name = core.words_db.gen_area_name(params)

        world = core.create(World, params.merge(:name => world_name, :size => size, :depth => depth))
        populate_area(core, world, config)
        world.finalize
        world
    end

    private
    def set_defaults(config)
        config[:world_size]         ||= 3
        config[:world_depth]        ||= 3
        config[:openness]           ||= 0.75 # Larger numbers lead to more rooms overall
        config[:connectedness]      ||= 0.75 # Larger numbers lead to more passageways
        config[:area_size_tendency] ||= 0.35 # Larger numbers move the balance of small/large rooms towards the large end
    end

    def generate_area(core, size, depth, parent_area, config)
        Log.debug("Generating area of size #{size} in #{parent_area.name}", 6)

        # Find and add a suitable zone template.
        parent_zone_type = parent_area.respond_to?(:zone_type) ? parent_area.zone_type : nil

        params = Zone.get_params(core, :parent => parent_zone_type, :depth => depth)

        Log.debug(params.inspect, 6)
        name = "#{core.words_db.gen_area_name(params)}-#{rand(1000)}"

        area = if (depth < 1) || (rand() < config[:area_size_tendency])
            Log.debug("Generating room #{name}", 5)
            core.create(Room, params.merge(:name => name))
        else
            Log.debug("Generating area #{name} of size #{size} and depth #{depth}", 5)
            core.create(Area, params.merge(:name => name, :size => size, :depth => depth))
        end

        # Populate the empty zone.
        # ZoneTemplate.populate_zone(area, size, depth)

        if Area === area
            # The config will almost certainly be modified by the zone template
            populate_area(core, area, config, parent_area)
        end

        area
    end

    # Generate sub-areas, and clean up excess/broken connections.
    def populate_area(core, area, config, parent_area=nil)
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
                if noisemap.get_scaled(iX, iY, 0.0, 1.0) < config[:openness]
                    # Create a zone at these coordinates
                    subarea = generate_area(core, area.size, area.depth - 1, area, config)
                    area.set_zone(x, y, subarea)

                    Log.debug("Set subarea #{subarea.name} with coords #{subarea.get_full_coordinates.inspect}", 7)

                    # Potentially generate connectivity information
                    if Room === subarea
                        if noisemap.get_scaled(iX-1, iY,   0.0, 1.0) < config[:connectedness]
                            Log.debug("Connecting room to the west", 9)
                            subarea.connect_to(:west)
                        end
                        if noisemap.get_scaled(iX+1, iY,   0.0, 1.0) < config[:connectedness]
                            Log.debug("Connecting room to the east", 9)
                            subarea.connect_to(:east)
                        end
                        if noisemap.get_scaled(iX,   iY-1, 0.0, 1.0) < config[:connectedness]
                            Log.debug("Connecting room to the south", 9)
                            subarea.connect_to(:south)
                        end
                        if noisemap.get_scaled(iX,   iY+1, 0.0, 1.0) < config[:connectedness]
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

    metered :generate, :generate_area, :populate_area
end
end

class ZoneLineWorldFactory < WorldFactory
class << self
    def generate(core, config = {}, zone_types = [])
        set_defaults(config)

        if zone_types.empty?
            Log.debug("generating default types")
            zone_types = Array.new(2) { Zone.zones_at_depth(core).rand }
            Log.debug(zone_types)
        end

        world = core.create(World, Zone.get_params(core, :depth => 1).merge(:name => "Fantasmagoria", :size => zone_types.size, :depth => 1))

        zones = []
        zone_types.each_with_index do |zone_type, i|
            params = Zone.get_params(core, :type => zone_type)
            r = core.create(Room, params.merge(:name => "Fantasm of #{zone_type}"))
            r.connect_to(:east)
            r.connect_to(:west)

            Log.debug("setting #{i}")
            world.set_zone(i, 0, r)

            zones << r
        end
        Log.debug('--')

         zones[0].remove_connection(:west)
        zones[-1].remove_connection(:east)

        world.check_consistency
        world.finalize
        world
    end
end
end

