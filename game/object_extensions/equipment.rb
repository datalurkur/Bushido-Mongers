=begin
16:54 <@datalurkur> I think an Equipment module is in order.
16:54 <@datalurkur> And basically this describes a creature that's intelligent enough to use tools.
16:55 <@datalurkur> With this will come a list of slots per body type that can hold equipment, and the types of equipment it can hold.
16:55 <@datalurkur> And the inventory will just be a list of equipment attached to slots along with the contents of any of that equipment that happens to be a container.
=end

module Inventory
    attr_reader :inventory

    def equip(part, equipment)
        @inventory ||= {}
        if @inventory[part.type].nil?
            @inventory[part.type] = equipment
        else
            raise "Couldn't equip #{equipment}; already wearing #{@inventory[part.type]}"
        end
    end
end

module Equipment
    include Inventory

    class << self
        def at_creation(instance, params)
            Log.debug(params)
            instance.random_equipment
        end

        def at_destruction(instance)
            # drop equipment on death, or leave it on the body to be pulled off?
        end
    end

    def random_equipment
        external_body_parts.each do |part|
            if part.has_property?(:can_equip) && !part.can_equip.empty?
                Log.debug([part, part.can_equip])
                rand_type = @core.db.random(part.can_equip.rand)

                creation_hash = {}

                # Pick random component type
                Log.debug(rand_type)
                components = @core.db.info_for(rand_type, :required_components)
                Log.debug(components)

                if components
                    components.map! do |comp|
                        Log.debug(@core.db.random(comp))
                        @core.db.create(@core, @core.db.random(comp))
                    end
                    creation_hash[:components] = components
                end

                creation_hash[:quality] = :standard

                # FIXME: adjust size based on size of self, like bodies do.
                equip(part, @core.db.create(@core, rand_type, creation_hash))
            end
        end
    end
end
