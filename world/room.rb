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

    def monicker
        @params[:zone].monicker
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

    def insert_object(object)
        Log.debug("Inserting #{object.monicker} into #{@name}", 6)
        @objects << object
    end
    def add_object(object,type=:internal)
        Log.debug("Adding #{object.monicker} into #{@name}", 6)
        if type != :internal
            Log.warning(["Rooms cannot be comprised of #{type.inspect} objects", caller])
        end
        @objects << object
    end
    def remove_object(object)
        unless @objects.include?(object)
            Log.error("#{object.monicker} not found in #{@name}") 
        end
        Log.debug("Removing #{object.monicker} from #{@name}", 6)
        @objects.delete(object)
    end

    # Determines how a leaf populates itself
    def populate(core)
        Log.debug("Populating leaf #{name}")

        # FIXME: This should be somewhere else, and not so inclusive.
        @parent.add_starting_location(self)# if Chance.take(:coin_toss)

        populate_npcs(core)
        populate_items(core)
    end

    def populate_npcs(core)
        npc_types = core.db.info_for(self.zone.type, :spawn_npcs)

        Log.debug("No acceptable NPC types found for #{self.zone.type}!") if npc_types.empty?

        # Actually spawn the NPCs; just one of each type for now.
        npc_types.each do |type|
            if Chance.take(core.db.info_for(type, :spawn_chance))
                core.db.create(core, type, {:position => self })
            end
        end
    end

    def populate_items(core)
        item_types = core.db.info_for(self.zone.type, :spawn_items)

        # Actually spawn the items.
        item_types.each do |type|
            core.db.create(core, type, {:position => self })
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
