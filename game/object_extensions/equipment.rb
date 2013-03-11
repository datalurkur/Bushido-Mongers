require './util/exceptions'

module Inventory
    def wear(part, equipment)
        raise(FailedCommandError, "Can't wear #{equipment.monicker}; already wearing #{part.worn}") if part.full?(:worn)
        equipment.equip_on(part)
    end

    def grasp(part, object)
        raise(FailedCommandError, "Can't hold #{object.monicker}; already holding #{part.grasped}") if part.full?(:graped)
        object.grasped_by(part)
    end

    # TODO - stash priorities for a) particular items (e.g. arrows go in quiver) and b) particular commands.
    def stash(object)
        Log.debug("Stashing #{object.monicker}")
        if grasper = available_grasper
            grasp(grasper, object)
        elsif container = available_container
            object.move_to(container)
        else
            raise(FailedCommandError, "Couldn't stash #{object.monicker}; no place to put it.")
        end
    end

    def remove(equipment)
        # TODO - check for curses :-p
        # TODO - check that equipment is actually equipped
        raise(FailedCommandError, "Not wearing #{equipment.monicker}.") unless all_equipment(:worn).include?(equipment)
        unless stash(equipment)
            equipment.move_to(self.absolute_position)
        end
    end

    def available_grasper
        all_body_parts.select { |bp| bp.composed_of?(:grasped) }.each do |part|
            Log.debug("Looking at #{part.monicker} for grasping")
            return part unless part.full?(:grasped)
        end
        nil
    end

    def available_container
        containers_in_inventory.each do |cont|
            Log.debug("Looking at #{cont.monicker} for container")
            return cont if cont.open? && !cont.full?
        end
        nil
    end

    def all_equipment(position)
        all_body_parts.select { |bp| bp.composed_of?(position) }.map do |bp|
            bp.container_contents(position)
        end.flatten
    end

    def containers_in_inventory
        containers([:grasped, :worn])
    end

    def has_weapon?
        weapon = nil
        candidates = all_equipment(:grasped).select { |o| o.is_type?(:weapon) }
        unless candidates.empty?
            Log.debug(candidates)
            # TODO - check handedness, and ignore or penalize weapon without enough hands.
            @default_weapon = candidates[0]
            true
        else
            false
        end
    end

    def weapon
        @default_weapon
    end
end

module Equipment
    include Inventory

    class << self
        def at_creation(instance, params)
            raise(MissingObjectExtensionError, "Equipment can only be used on a corporeal!") unless Corporeal === instance
            instance.add_random_equipment
        end

        def at_destruction(instance, destroyer, vaporize)
            # drop equipment on death, or leave it on the body to be pulled off?
        end
    end

    def add_random_equipment
        external_body_parts.each do |part|
            if part.properties[:can_equip] && !part.properties[:can_equip].empty?
                Log.debug(["Looking for equipment worn on #{part.monicker}", part.properties[:can_equip]], 6)
                equipment_type = @core.db.random(part.properties[:can_equip].rand)
                equipment_piece = @core.create(equipment_type, :randomize => true)
                Log.debug(["Found", equipment_piece], 6)
                wear(part, equipment_piece)
            end
        end
    end
end
