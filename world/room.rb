require './game/tables'
require './world/zone'

module ZoneWithKeywords
    def zone_type
        raise(StandardError, "Zone has no type!") unless @params[:type]
        @params[:type]
    end

    def zone_info
        raise(StandardError, "Zone has no core!") unless @core
        @core.db.info_for(self.zone_type)
    end

    def keywords
        self.zone_info[:keywords]
    end
end

class Room < ZoneLeaf
    include ZoneWithKeywords

    attr_reader :objects

    def initialize(core, name, params={})
        @core    = core
        @params  = params

        @objects = []

        super(name)
    end

    def insert_object(object)
        Log.debug("Inserting #{object.monicker} into #{@name}", 6)
        @objects << object
    end

    def add_object(object, type=:internal)
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
    def populate
        Log.debug("Populating leaf #{name}")

        # FIXME: This should be somewhere else, and not so inclusive.
        @parent.add_starting_location(self)# if Chance.take(:coin_toss)

        populate_npcs
        populate_items
    end

    def populate_npcs
        npc_types = @core.db.info_for(self.zone_type, :spawn_npcs)

        Log.debug("No acceptable NPC types found for #{self.zone_type}!") if npc_types.empty?

        # Actually spawn the NPCs; just one of each type for now.
        npc_types.each do |type|
            if Rarity.roll(@core.db.info_for(type, :spawn_rarity))
                @core.create(type, {:position => self })
            end
        end
    end

    def populate_items
        item_types = @core.db.info_for(self.zone_type, :spawn_items)

        # Actually spawn the items.
        item_types.each do |type|
            @core.create(type, {:position => self })
        end
    end
end

class Area < ZoneContainer
    include ZoneWithKeywords

    def initialize(core, name, size, depth, params={})
        Log.debug("Creating #{name} room with #{params.inspect}")
        @core   = core
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
    def populate
        Log.debug("Populating area #{name}")

        # FIXME - This will be more complex based on keywords
        leaves.each do |leaf|
            leaf.populate
        end
    end
end
