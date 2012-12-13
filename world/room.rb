require 'world/zone'
require 'game/npc'

module ZoneWithKeywords
    attr_accessor :zone

    def keywords
        @keywords ||= []
    end

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
end

class Room < ZoneLeaf
    include ZoneWithKeywords

    attr_reader :contents
    attr_reader :occupants

    def initialize(name, keywords=[])
        add_keywords(keywords)
        super(name)

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

        # FIXME - This will be more complex based on keywords
        if rand(10) < 5
            npc = NPC.new("Test NPC #{rand(100000)}")
            npc.set_position(self)
            core.add_npc(npc)
        end
    end
end

class Area < ZoneContainer
    include ZoneWithKeywords
    
    def initialize(name, size, depth, keywords=[])
        add_keywords(keywords)
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
