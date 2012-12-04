require 'ai/behavior'

NPCBehavior.define(:random_movement) do |core, actor|
    actor.move(actor.location.connected_directions.rand)
end

NPCBehavior.define(:attack, &:are_enemies_present?) do |core, actor|
    attackee = NPCBehavior.enemies_present.rand
    actor.attack(attackee)
end
