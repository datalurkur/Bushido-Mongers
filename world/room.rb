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

    def monicker; @name; end

    def add_object(object, type)
        raise(UnexpectedBehaviorError, "Rooms cannot be comprised of #{type.inspect} objects") unless type == :internal
        Log.debug("Adding #{object.monicker} into #{@name}", 6)
        @objects << object
    end

    def remove_object(object, type)
        raise(UnexpectedBehaviorError, "Rooms cannot be comprised of #{type.inspect} objects") unless type == :internal
        unless @objects.include?(object)
            Log.error("#{object.monicker} not found in #{@name}") 
        end
        Log.debug("Removing #{object.monicker} from #{@name}", 6)
        @objects.delete(object)
    end
    def component_destroyed(object, type, destroyer); remove_object(object, type); end

    # Determines how a leaf populates itself
    def populate
        Log.debug("Populating leaf #{name}")
        populate_items
    end

    def populate_items
        item_types = @core.db.info_for(self.zone_type, :spawn_items)

        # Actually spawn the items.
        item_types.each do |type|
            @core.create(type, {:position => self, :randomize => true})
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

    # Decides whether an Area populates its sub-Areas / Leaves directly, or defers to them to do so
    def populate
        Log.debug("Populating area #{name}")

        # FIXME - This will be more complex based on keywords
        leaves.each do |leaf|
            leaf.populate
        end
    end
end
