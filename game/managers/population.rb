# TODO
#   - Listen for ticks and automatically spawn new population members
#   - Listen for death messages and adjust rarity accordingly
#   - Listen for move messages and disable spawns that have players in them (no fun in spawning things directly on top of players)

class PopulationManager
    # TODO - Make the population manager save-/load-friendly
    def initialize(core)
        @core = core
    end

    def listens_for; [:unit_moves,:unit_killed,:unit_renamed]; end

    def setup
        @named          = {}
        @groups         = {}
        @diabled_spawns = []

        load_from_raws

        listens_for.each do |message_type|
            Message.register_listener(@core, message_type, self)
        end
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
        listens_for.each do |message_type|
            Message.unregister_listener(@core, message_type, self)
        end

        @groups          = nil
        @disabled_spawns = nil
    end

    def process_message(message)
        # Get the population type involved if this will affect a population type
        unit = case message.type
        when :unit_moves
            message.agent
        when :unit_killed
            message.target
        end

        if unit && @groups[unit.get_type].nil?
            raise(NoMatchError, "No record of population type #{unit.get_type.inspect}")
        end

        case message.type
        when :unit_moves
            unit_moves(unit, message.origin, message.destination)
        when :unit_killed
            unit_moves(unit, message.location, nil)
        when :tick
            Log.info("#{self.class} spawning new population members")
            Log.warning("IMPLEMENT ME")
        when :unit_renamed
            if message.params[:old_name]
                old_name = hash_name(message.old_name)
                new_name = hash_name(message.name)
                if @named[old_name]
                    @named[new_name] = @named[old_name]
                    @named.delete(old_name)
                end
            end
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
            return @groups[type_or_name][:populations]
        else
            name = hash_name(type_or_name)
            if @named[name]
                return {@named[name] => 1}
            else
                return {}
            end
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

        # Determine the specific morphism of the agent
        unless hash[:morphism]
            morphic_choices = []
            morphic_parts   = @core.db.info_for(type, :morphic)
            morphic_parts.each do |morphic_part|
                morphic_choices.concat(morphic_part[:morphism_classes])
            end
            hash[:morphism] = morphic_choices.uniq.rand
        end
        Log.debug("#{type} will be #{hash[:morphism]}")

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
            random_profession = @core.db.static_types_of(:profession).rand
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

        unit_moves(agent, nil, agent.absolute_position)
        agent
    end

    private
    def load_from_raws
        @core.db.instantiable_types_of(:archetype).each do |npc_type|
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

    def unit_moves(unit, src, dst)
        type = unit.get_type
        if src
            unless @groups[type][:populations][src]
                raise(NoMatchError, "No population of #{type} found at #{src}")
            end
            @groups[type][:populations][src] -= 1
            @groups[type][:populations].delete(src) if @groups[type][:populations][src] == 0
        end

        if dst
            @groups[type][:populations][dst] ||= 0
            @groups[type][:populations][dst] += 1
        end

        if unit.name
            unit_name = hash_name(unit.name)
            if dst
                @named[unit_name] = dst
            else
                @named.delete(unit_name)
            end
        end
    end

    def hash_name(name)
        name.downcase.to_sym
    end
end
