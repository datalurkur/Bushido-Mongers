=begin
16:54 <@datalurkur> I think an Equipment module is in order.
16:54 <@datalurkur> And basically this describes a creature that's intelligent enough to use tools.
16:55 <@datalurkur> With this will come a list of slots per body type that can hold equipment, and the types of equipment it can hold.
16:55 <@datalurkur> And the inventory will just be a list of equipment attached to slots along with the contents of any of that equipment that happens to be a container.
=end

module Inventory
    def wear(part, equipment)
        if part.full?(:worn)
            raise "Can't wear #{equipment.monicker}; already wearing #{part.worn_objects}"
        end
        equipment.equip_on(part)
    end

    def grasp(part, object)
        if part.full?(:grasped)
            raise "Can't hold #{object.monicker}; already holding #{part.grasped_objects}"
        end
        object.grasped_by(part)
    end

    # TODO - stash priorities for a) particular items and b) particular commands.
    def stash(object)
        Log.debug("Stashing #{object.type}")
        # Try grabbing it first.
        self.grasping_parts.each do |part|
            Log.debug("Looking at #{part.type} for grasping")
            unless part.full?(:grasped)
                return grasp(part, object)
            end
        end
        # TODO - Next, look for a container to stash it in.
        (worn_containers + grasped_containers).each do |cont|
            unless cont.full?
                return object.move_to(pot_container)
            end
        end
    end

    def all_grasped_objects
        all_body_parts.collect { |bp| bp.grasped_objects }.flatten
    end

    def all_worn_objects
        all_body_parts.collect { |bp| bp.worn_objects }.flatten
    end

    def containers_in_inventory
        grasped_containers + worn_containers
    end

    def grasped_containers
        containers(:grasped)
    end

    def worn_containers
        containers(:worn)
    end
end

module Equipment
    include Inventory

    class << self
        def at_creation(instance, params)
            unless instance.uses?(Corporeal)
                raise "Equipment can only be used on a corporeal!"
            end
            instance.random_equipment
        end

        def at_destruction(instance)
            # drop equipment on death, or leave it on the body to be pulled off?
        end
    end

    def random_equipment
        external_body_parts.each do |part|
            if part.has_property?(:can_equip) && !part.can_equip.empty?
                Log.debug("Looking for equipment worn on #{part.monicker}")
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
                creation_hash[:position] = $nowhere

                Log.debug("Wearing new #{rand_type} on #{part.type}")
                wear(part, @core.db.create(@core, rand_type, creation_hash))
            end
        end
        # TEST FUNCTIONALITY
        # Now, insert rocks until we can't anymore.
    end
end
