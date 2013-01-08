Behavior.define(:random_movement) do |actor|
    direction = actor.position.connected_directions.rand
    if direction
        Log.debug("#{actor.name} moves to the #{direction}")
        actor.move(direction)
        true
    else
        Log.debug("#{actor.name} sits around with nowhere to go")
        false
    end
end

Behavior.define(:attack) do |actor|
    aligned_list = Commands.filter_objects(actor, :position, :aligned)
    enemies = aligned_list.select { |npc| Behavior.are_enemies?(npc, actor) }
    if enemies.empty?
        false
    else
        attackee = enemies.first
        Log.debug("#{actor.monicker} is attacking #{attackee.monicker}", 5)
        actor.do_command(:attack, {:agent => actor, :target => attackee})
        true
    end
end

Behavior.define(:consume) do |actor|
    consumable_type = actor.class_info(:consumes) || :consumable
    consumables = [:position, :inventory].collect do |location|
        Commands.filter_objects(actor, location, consumable_type)
    end.flatten

    if consumables.empty?
        false
    else
        consumable = consumables.first
        actor.do_command(:consume, {:agent => actor, :target => consumable})
        true
    end
end

BehaviorSet.define(:random_attack_and_move, {0 => [:attack], 1 => [:random_movement]})
BehaviorSet.define(:roam_and_consume, {0 => [:consume], 1 => [:random_movement]})
