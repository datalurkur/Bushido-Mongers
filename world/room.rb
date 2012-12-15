require 'world/zone'
require 'game/npc'

module ZoneWithKeywords
    attr_accessor :zone

    def keywords
        @params[:keywords] ||= []
    end

=begin
    def add_keywords(keywords)
        keywords.each { |kw| add_keyword(kw) }
    end

    def add_keyword(keyword)
        keywords << keyword
        keywords.uniq!
    end

    def remove_keyword(keyword)
        keywords.delete(keyword)
    end
=end
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

    # Determines how a leaf populates itself in the absence of parent data
    def populate(core)
        Log.debug("Populating leaf #{name}")

        # FIXME: This should be somewhere else, and not so inclusive.
        @parent.add_starting_location(self)# if rand(2) == 0

        populate_npcs(core)
    end

    def populate_npcs(core)
        may_spawn     = core.db.expand_types(@params[:may_spawn]     || [])
        always_spawns = core.db.expand_types(@params[:always_spawns] || [])
        never_spawns  = core.db.expand_types(@params[:never_spawns]  || [])

        # Find NPC types suitable to create here.
        npc_types = core.db.types_of(:npc)
        acceptable_types  = always_spawns
        acceptable_types += npc_types.select do |type|
            may_spawn.include?(type) &&
            !never_spawns.include?(type)
        end
        acceptable_types.uniq!

        # This number will need serious tweaking.
        (always_spawns.size + rand(acceptable_types.size)).floor.times do |i|
            type = acceptable_types.rand
            unless always_spawns.empty?
                type = always_spawns.shift
            end

            # Add the NPC.
            npc = NPC.new("#{type} #{rand(100000)}", type, core.db)
            npc.set_position(self)
            core.add_npc(npc)
        end
    end
end

class Area < ZoneContainer
    include ZoneWithKeywords
    
    def initialize(name, size, depth, params={})
        @params = params
        super(name, size, depth)
    end

    def add_starting_location(location)
        puts "#{self.name}.add_starting_location(#{location}): #{@parent.inspect}"
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
