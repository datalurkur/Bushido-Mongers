require './game/core'
require './game/managers/population'

class DefaultCore < GameCore
    # MANAGER ACCESSORS
    # =================
    def populations; @population_manager; end

    def create_npc(type, hash = {})
        create_agent(type, false, hash)
    end

    def create_character(lobby, username, details)
        agent_params = details.reject { |k,v| [:archetype].include?(k) }

        ret = nil
        @usage_mutex.synchronize do
            character = create_agent(details[:archetype], true, agent_params)
            characters[username] = character
            Log.info("Character #{character.monicker} created for #{username}")
            character.set_user_callback(lobby, username)

            ret = character
        end
        return ret
    end

    private
    def create_agent(type, player, hash = {})
        Log.debug("Creating #{type} agent", 6)

        unless hash[:position]
            spawn_location_types = @population_manager[type][:spawns]
            hash[:position]      = @world.get_random_location(spawn_location_types)
            hash[:position]    ||= @world.get_random_location
        end

        # Determine the specific morphism of the agent
        unless hash[:morphism]
            morphic_choices = []
            morphic_parts   = @db.info_for(type, :morphic)
            morphic_parts.each do |morphic_part|
                morphic_choices.concat(morphic_part[:morphism_classes])
            end
            hash[:morphism] = morphic_choices.uniq.rand
        end
        Log.debug("#{type} will be #{hash[:morphism]}", 6)

        agent = create(type, hash)

        Transforms.transform(:animate, self, agent, hash)

        agent.setup_extension(Knowledge, hash)
        if player && !hash[:name]
            raise(ArgumentError, "Player was not given a name")
        end

        starting_skills = []
        feral           = agent.class_info[:feral] && !player
        if player
            agent.setup_extension(Character, hash)
            # FIXME - Add starting skills from new player info
            # As a hack, just add a random profession for now
            random_profession = @db.static_types_of(:profession).rand
            starting_skills = @db.info_for(random_profession, :skills)
        else
            agent.setup_extension(NpcBehavior, hash)
            if agent.class_info[:typical_profession]
                profession_info = @db.info_for(agent.class_info[:typical_profession])
                agent.set_behavior(profession_info[:typical_behavior])
                starting_skills = profession_info[:skills]
            end
        end
        agent.setup_skill_set(starting_skills)

        unless feral
            agent.setup_extension(Equipment, hash)
        else
            Log.debug("Since agent is feral, no equipment will be generated", 6)
        end

        agent
    end

    def setup_world(args)
        Log.debug("Creating world")
        factory_klass = args[:factory_klass] || WorldFactory
        @world = factory_klass.generate(self, args)

        Log.debug("Populating world with NPCs and items")
        @world.populate
    end

    def pack_world
        WorldFactory.pack(@world)
    end

    def unpack_world(hash)
        @world = WorldFactory.unpack(hash)
    end

    def teardown_world
        @world = nil
    end

    def setup_managers(args)
        # Seed the world with NPCs
        # ------------------------
        @population_manager = PopulationManager.new(self)
        @population_manager.setup

        seed_population
    end

    def pack_managers
        hash = {}
        hash[:population] = PopulationManager.pack(@population_manager)
        hash
    end

    def unpack_managers(hash)
        @population_manager = PopulationManager.unpack(hash[:population])
    end

    def teardown_managers
        @population_manager.teardown
        @population_manager = nil
    end

    def seed_population
        Log.debug("Seeding initial population", 4)
        @population_manager.each do |type, info|
            real_spawn_locations = @world.leaves.select { |leaf| info[:spawns].include?(leaf.zone_type) }
            mobs_to_spawn        = (Rarity.value_of(info[:rarity]) * real_spawn_locations.size).ceil

            Log.debug("Seeding #{mobs_to_spawn} #{type}s", 4)
            mobs_to_spawn.to_i.times { create_agent(type, false, {:position => real_spawn_locations.rand}) }
        end
    end
end
