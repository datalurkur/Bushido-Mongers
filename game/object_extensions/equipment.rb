=begin
16:54 <@datalurkur> I think an Equipment module is in order.
16:54 <@datalurkur> And basically this describes a creature that's intelligent enough to use tools.
16:55 <@datalurkur> With this will come a list of slots per body type that can hold equipment, and the types of equipment it can hold.
16:55 <@datalurkur> And the inventory will just be a list of equipment attached to slots along with the contents of any of that equipment that happens to be a container.
=end

module Inventory
    INV_TYPES = [:worn, :held]

    def init_inventory
        @inventory ||= {}
        INV_TYPES.each do |type|
            @inventory[type] = {}
        end
    end

    def wear(part, equipment)
        if add(:worn, part, equipment)
            return part.type
        else
            raise "Couldn't wear #{equipment}; already wearing #{@inventory[:worn][part.type]}"
        end
    end

    def hold(equipment)
    end

    def hold(part, object)
        unless part.has_property?(:is_container)
            raise "Couldn't hold #{object} in #{part.inspect}!"
        end
        if add(:held, part, object)
            return part.type
        else
            raise "Couldn't hold #{object}; already holding #{@inventory[:held][part.type]}"
        end
    end

    def stash(object)
        # TODO - search for containers in inventory, stash object within
        # hold(instantiated_hand, object)
    end

    def select_inventory(&block)
        list = []
        INV_TYPES.each do |type|
            @inventory[type].each do |part, equipment|
                if (block_given? && block.call(equipment)) || !block_given?
                    list << equipment
                end
            end
        end
        list
    end

    private
    def add(type, part, equipment)
        init_inventory unless @inventory
        if @inventory[type][part.type].nil?
            @inventory[type][part.type] = equipment
        else
            nil
        end
    end
end

module Equipment
    include Inventory

    class << self
        def at_creation(instance, params)
            instance.init_inventory
            instance.random_equipment
        end

        def at_destruction(instance)
            # drop equipment on death, or leave it on the body to be pulled off?
        end
    end

    def random_equipment
        external_body_parts.each do |part|
            if part.has_property?(:can_equip) && !part.can_equip.empty?
                rand_type = @core.db.random(part.can_equip.rand)

                creation_hash = {}

                # Pick random component type
                components = @core.db.info_for(rand_type, :required_components)
                if components
                    components.map! do |comp|
                        @core.db.create(@core, @core.db.random(comp))
                    end
                    creation_hash[:components] = components
                end

                creation_hash[:quality] = :standard

                wear(part, @core.db.create(@core, rand_type, creation_hash))
            end
        end
    end
end
