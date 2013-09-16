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

    def self.pack(instance); instance.pack; end
    def self.unpack(core, hash)
        raise(MissingProperty, "Room data corrupted") unless hash[:uid] && hash[:params]
        obj = self.new(core, hash[:uid], hash[:params])
        obj.unpack(hash)
        obj
    end

    def initialize(core, uid, params={})
        @params  = params
        @objects = []
        raise(MissingProperty, "Room must have a name") unless params[:name]
        super(core, uid, params[:name])
    end

    def pack
        super().merge(
            :objects => @objects,
            :params  => @params
        )
    end

    def unpack(hash)
        super(hash)
        raise(MissingProperty, "Room data corrupted") unless hash[:objects]
        @objects = hash[:objects]
    end

    def monicker; @name; end

    def get_contents(type)
        raise(ArgumentError, "Invalid room content type #{type}.") unless type == :internal
        @objects.collect { |obj_id| @core.lookup(obj_id) }
    end

    def add_object(object, type)
        raise(UnexpectedBehaviorError, "Rooms cannot be comprised of #{type.inspect} objects") unless type == :internal
        Log.debug("Adding #{object.monicker} into #{@name}", 6)
        @objects << object.uid
    end

    def remove_object(object, type)
        raise(UnexpectedBehaviorError, "Rooms cannot be comprised of #{type.inspect} objects") unless type == :internal
        unless @objects.include?(object.uid)
            Log.error(["#{object.monicker} not found in #{@name}", caller])
        end
        Log.debug("Removing #{object.monicker} from #{@name}", 6)
        @objects.delete(object.uid)
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

    def self.pack(instance); instance.pack; end
    def self.unpack(core, hash)
        raise(MissingProperty, "Area data corrupted") unless hash[:uid] && hash[:params]
        obj = self.new(core, hash[:uid], hash[:params])
        obj.unpack(hash)
        obj
    end

    def initialize(core, uid, params={})
        Log.debug("Initializing #{params[:name]}")
        @params = params
        [:name, :size, :depth].each do |key|
            raise(MissingProperty, "Area must have a #{key}") unless params[key]
        end
        super(core, uid, params[:name], params[:size], params[:depth])
    end

    def pack
        super().merge(:params => @params)
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
