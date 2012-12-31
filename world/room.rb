require 'game/tables'
require 'world/zone'

module ZoneWithKeywords
    def zone
        raise "Template not defined!" unless @params[:template]
        @params[:template]
    end

    def keywords
        @params[:keywords] ||= []
    end
end

class Room < ZoneLeaf
    include ZoneWithKeywords

    attr_reader :contents
    attr_reader :occupants

    def initialize(name, params={})
        super(name)

        @params = params

        @contents  = []
        @occupants = []
    end

    def add_occupant(occupant)
        @occupants << occupant
    end

    def remove_occupant(occupant)
        @occupants.delete(occupant)
    end

    # Determines how a leaf populates itself
    def populate(core)
        Log.debug("Populating leaf #{name}")

        # FIXME: This should be somewhere else, and not so inclusive.
        @parent.add_starting_location(self)# if Chance.take(:coin_toss)

        populate_npcs(core)
    end

    def populate_npcs(core)
        may_spawn     = core.db.types_of(@params[:may_spawn]     || [])
        always_spawns = core.db.types_of(@params[:always_spawns] || [])
        never_spawns  = core.db.types_of(@params[:never_spawns]  || [])
        Log.debug(["Creating NPCs for #{self.name} with spawn details", may_spawn, always_spawns, never_spawns])

        # Find NPC types suitable to create here, based on NPC info.
        npc_types = core.db.types_of(:npc)
        acceptable_types = npc_types.select do |type|
            (
                may_spawn.include?(type) &&
                !never_spawns.include?(type)
            ) || (
                core.db.info_for(type, :can_spawn_in) &&
                core.db.info_for(type, :can_spawn_in).include?(self.zone)
            )
        end
        acceptable_types.uniq!

        Log.debug("Can create #{(always_spawns + acceptable_types).inspect} in #{self.zone}", 6)
        Log.debug("No acceptable NPC types found for #{self.zone}!") if always_spawns.empty? && acceptable_types.empty?

        # Actually spawn the NPCs.
        always_spawns.each { |type| add_npc(core, type) }

        acceptable_types.each do |type|
            add_npc(core, type) if Chance.take(core.db.info_for(type, :spawn_chance))
        end
    end

    private
    def add_npc(core, type)
        # FIXME: Generate better names?
        core.add_npc(core.db.create(core, type, {:name => "#{type} #{rand(100000)}", :initial_position => self}))
    end
end

class Area < ZoneContainer
    include ZoneWithKeywords

    def initialize(name, size, depth, params={})
        @params = params
        super(name, size, depth)
    end

    def add_starting_location(location)
        if @parent
            @parent.add_starting_location(location) if @parent
        else
            starting_locations << location
        end
    end

    # Decides whether an Area populates its sub-Areas / Leaves directly, or defers to them to do so
    def populate(core)
        Log.debug("Populating area #{name}")

        # FIXME - This will be more complex based on keywords
        leaves.each do |leaf|
            leaf.populate(core)
        end
    end
end
