Behavior.define(:random_movement) do |actor|
    position = actor.absolute_position

    # A Dwarf in a bag is kinda just screwed
    return false unless Room === position

    direction = position.connected_directions.rand
    if direction
        location = position.get_adjacent(direction)
        actor.move_to(location)
        true
    else
        false
    end
end

Behavior.define(:flee) do |actor|
    raise "Cannot flee without perceiving." unless actor.uses?(Perception)
    aligned_list = actor.filter_objects(:position, :aligned)
    enemies = aligned_list.select { |npc| Behavior.are_enemies?(npc, actor) }
    if enemies.empty?
        false
    else
        position = actor.absolute_position

        # A Dwarf trapped in a bag with a voracious wolf is *doubly* screwed
        return false unless Room === position

        direction = position.connected_directions.rand
        if direction
            location = position.get_adjacent(direction)
            actor.move(location)
            true
        else
            false
        end
    end
end

Behavior.define(:attack) do |actor|
    raise "Cannot attack without perceiving." unless actor.uses?(Perception)
    aligned_list = actor.filter_objects(:position, :aligned)
    enemies = aligned_list.select { |npc| Behavior.are_enemies?(npc, actor) }
    if enemies.empty?
        false
    else
        attackee = enemies.first
        #Log.debug("#{actor.monicker} is attacking #{attackee.monicker}", 5)
        actor.do_command(:attack, {:agent => actor, :target => attackee})
        true
    end
end

Behavior.define(:consume) do |actor|
    raise "Cannot consume without perceiving." unless actor.uses?(Perception)

    consumable_type = actor.class_info(:consumes) || :consumable
    consumables = [:position, :inventory].collect do |location|
        actor.filter_objects(location, consumable_type)
    end.flatten

    if consumables.empty?
        Log.debug("#{actor.monicker} finds nothing to consume", 6)
        false
    else
        consumable = consumables.first
        actor.do_command(:consume, {:agent => actor, :target => consumable})
        true
    end
end

BehaviorSet.define(:flee_if_threatened, {0 => [:flee]})
BehaviorSet.define(:random_attack_and_move, {0 => [:attack], 1 => [:random_movement]})
BehaviorSet.define(:roam_and_consume, {0 => [:consume], 1 => [:random_movement]})
