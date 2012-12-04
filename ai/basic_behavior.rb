require 'ai/behavior'

NPCBehavior.define(:random_movement) do |actor|
    actor.move(actor.location.connected_directions.rand)
end

NPCBehavior.define(:attack, &:are_enemies_present?) do |actor|
    attackee = NPCBehavior.enemies_present.rand
    actor.attack(attackee)
end

BehaviorSet.define(:random_attack_and_move, {0 => :attack, 1 => :random_movement})
