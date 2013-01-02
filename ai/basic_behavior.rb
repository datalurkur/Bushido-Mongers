require 'ai/behavior_set'

Behavior.define(:random_movement) do |actor|
    direction = actor.position.connected_directions.rand
    if direction
        Log.debug("#{actor.name} moves to the #{direction}")
        actor.move(direction)
    else
        Log.debug("#{actor.name} sits around with nowhere to go")
    end
end

Behavior.define(:attack, :are_enemies_present?) do |actor|
    attackee = Behavior.enemies_present(actor).rand
    actor.do_command(:attack, {:agent => actor, :target => attackee})
end

BehaviorSet.define(:random_attack_and_move, {0 => [:attack], 1 => [:random_movement]})
