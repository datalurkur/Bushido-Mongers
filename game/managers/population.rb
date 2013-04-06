# TODO
#   - Listen for move / death messages and track population movement / dwindling
#   - Listen for ticks and automatically spawn new population members
#   - Listen for death messages and adjust rarity accordingly
#   - Listen for move messages and disable spawns that have players in them (no fun in spawning things directly on top of players)

class PopulationManager
    # TODO - Make the population manager save-/load-friendly
    def initialize(core)
        @groups = {}
        @core   = core
    end

    def setup
        load_from_raws
        seed_population
    end

    def get_info(type)
        raise(ArgumentError, "Unknown population #{type.inspect}") unless @groups.has_key?(type)
        @groups[type]
    end
    def enable_spawn(location)
        @disabled_spawns.delete(location)
    end
    def disable_spawn(location)
        (@disabled_spawns << location) unless @disabled_spawns.include?(location)
    end

    private
    def load_from_raws
        @core.db.find_subtypes(:archetype, {}, true).each do |npc_type|
            npc_info = @core.db.info_for(npc_type)
            add_group(npc_type, npc_info[:spawns_in], npc_info[:spawn_rarity])
        end
    end

    def add_group(type, spawn_locations, rarity)
        Log.debug(["Adding #{rarity.inspect} population group #{type.inspect}", spawn_locations])
        @groups[type] = {
            :spawns         => spawn_locations,
            :populations    => {},
            :rarity         => rarity
        }
    end

    def seed_population
        Log.debug("Seeding initial population")
        @groups.each do |type, info|
            real_spawn_locations = @core.world.leaves.select { |leaf| info[:spawns].include?(leaf.zone_type) }
            mobs_to_spawn        = (Rarity.value_of(info[:rarity]) * real_spawn_locations.size).ceil

            Log.debug("Seeding #{mobs_to_spawn} #{type}s")
            mobs_to_spawn.to_i.times { spawn(type, real_spawn_locations.rand) }
        end
    end

    def spawn(type, location)
        @core.create_agent(type, false, {:position => location})
        @groups[type][:populations][location] ||= 0
        @groups[type][:populations][location] += 1
    end
end
