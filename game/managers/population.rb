# TODO
#   - Listen for move / death messages and track population movement / dwindling
#   - Listen for ticks and automatically spawn new population members
#   - Listen for death messages and adjust rarity accordingly
#   - Listen for move messages and disable spawns that have players in them (no fun in spawning things directly on top of players)

class PopulationManager
    # TODO - Make the population manager save-/load-friendly
    def initialize(core)
        @core = core
    end

    def setup
        @groups         = {}
        @diabled_spawns = []

        load_from_raws

        Message.register_listener(@core, :unit_moves, self)
    end

    def seed_population
        Log.debug("Seeding initial population")
        @groups.each do |type, info|
            real_spawn_locations = @core.world.leaves.select { |leaf| info[:spawns].include?(leaf.zone_type) }
            mobs_to_spawn        = (Rarity.value_of(info[:rarity]) * real_spawn_locations.size).ceil

            Log.debug("Seeding #{mobs_to_spawn} #{type}s")
            mobs_to_spawn.to_i.times { create_agent(type, false, {:position => real_spawn_locations.rand}) }
        end
    end

    def teardown
        Message.unregister_listener(@core, :unit_moves, self)

        @groups          = nil
        @disabled_spawns = nil
    end

    def process_message(message)
        # Get the population type involved if this will affect a population type
        unit_type = case message.type
        when :unit_moves
            message.agent.get_type
        when :unit_killed,:object_destroyed
            message.target.get_type
        end

        if unit_type && @groups[unit_type].nil?
            raise(NoMatchError, "No record of population type #{unit_type.inspect}")
        end

        case message.type
        when :unit_moves
            unit_leaves(unit_type, message.origin)
            unit_enters(unit_type, message.destination)
        when :unit_killed,:object_destroyed
            unit_leaves(unit_type, message.location)
        when :tick
            Log.info("#{self.class} spawning new population members")
            Log.warning("IMPLEMENT ME")
        else
            Log.warning("#{self.class} ignoring message type #{message.type}")
        end
    end

    def [](type)
        raise(ArgumentError, "Unknown population #{type.inspect}") unless @groups.has_key?(type)
        @groups[type]
    end
    def locate(type_or_name)
        if @groups[type_or_name]
            @groups[type_or_name][:populations]
        else
            raise(NotImplementedError, "#{self.class} does not yet support lookups by name")
        end
    end
    def enable_spawn(location)
        @disabled_spawns.delete(location)
    end
    def disable_spawn(location)
        (@disabled_spawns << location) unless @disabled_spawns.include?(location)
    end

    def create_agent(type, player, hash = {})
        Log.debug("Creating #{type} agent", 6)

        raise(NoMatchError, "No record of population type #{type.inspect}") unless @groups[type]
        unless hash[:position]
            spawn_location_types = @groups[type][:spawns]
            hash[:position]      = @core.world.get_random_location(spawn_location_types)
            hash[:position]    ||= @core.world.get_random_location
        end
        @groups[type][:populations][hash[:position]] ||= 0
        @groups[type][:populations][hash[:position]] += 1

        agent = @core.create(type, hash)

        agent.setup_extension(Perception, hash)
        agent.setup_extension(Knowledge, hash)
        agent.setup_extension(Karmic, hash)
        if player && !hash[:name]
            raise(ArgumentError, "Player was not given a name")
        end

        starting_skills = []
        feral           = agent.class_info[:feral] && !player
        if player
            agent.setup_extension(Character, hash)
            # FIXME - Add starting skills from new player info
            # As a hack, just add a random profession for now
            random_profession = @core.db.types_of(:profession, false).rand
            starting_skills = @core.db.info_for(random_profession, :skills)
        else
            agent.setup_extension(NpcBehavior, hash)
            if agent.class_info[:typical_profession]
                profession_info = @core.db.info_for(agent.class_info[:typical_profession])
                agent.set_behavior(profession_info[:typical_behavior])
                starting_skills = profession_info[:skills]
            end
        end
        agent.setup_skill_set(starting_skills)

        agent.setup_extension(Equipment, hash) unless feral

        agent
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

    def unit_enters(type, location)
        @groups[type][:populations][location] ||= 0
        @groups[type][:populations][location] += 1
    end

    def unit_leaves(type, location)
        unless @groups[type][:populations][location]
            raise(NoMatchError, "No population of #{type} found at #{location.monicker}") 
        end
        @groups[type][:populations][location] -= 1
        @groups[type][:populations].delete(location) if @groups[type][:populations][location] == 0
    end
end
