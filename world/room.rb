require 'game/tables'
require 'world/zone'

module ZoneWithKeywords
    # The instantiated zone, a BushidoObject.
    def zone
        raise "Zone not defined!" unless @params[:zone]
        @params[:zone]
    end

    def keywords
        @params[:zone].keywords
    end
end

class Room < ZoneLeaf
    include ZoneWithKeywords

    attr_reader :objects

    def initialize(name, params={})
        @params  = params
        @objects = []
        super(name)
    end

    def add_object(object)
        @objects << object
    end

    def remove_object(object)
        Log.warning("Object not found in #{@name}") unless @objects.include?(object)
        @objects.delete(object)
    end

    # Determines how a leaf populates itself
    def populate(core)
        Log.debug("Populating leaf #{name}")

        # FIXME: This should be somewhere else, and not so inclusive.
        @parent.add_starting_location(self)# if Chance.take(:coin_toss)

        populate_npcs(core)
    end

    def populate_npcs(core)
        can_spawn = core.db.info_for(self.zone.type, :can_spawn)

        Log.debug("No acceptable NPC types found for #{self.zone.type}!") if can_spawn.empty?

        # Actually spawn the NPCs.
        can_spawn.each do |type|
            if Chance.take(core.db.info_for(type, :spawn_chance))
                npc = core.db.create(core, type, {:position => self })
            end
        end
    end
end

class Area < ZoneContainer
    include ZoneWithKeywords

    def initialize(name, size, depth, params={})
        Log.debug("Creating #{name} room with #{params.inspect}")
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
