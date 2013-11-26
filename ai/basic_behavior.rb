require './util/exceptions'

Behavior.define(:random_movement) do |actor|
    position = actor.absolute_position

    # A Dwarf in a bag is kinda just screwed
    return false unless Room === position

    direction = position.connected_directions.rand
    if direction
        location = position.get_adjacent(direction)
        actor.set_position(location, :internal, true)
        true
    else
        false
    end
end

Behavior.define(:flee) do |actor|
    enemies = Behavior.enemies_in_area(actor)
    if enemies.empty?
        false
    else
        position = actor.absolute_position

        # A Dwarf trapped in a bag with a voracious wolf is *doubly* screwed
        return false unless Room === position

        direction = position.connected_directions.rand
        if direction
            location = position.get_adjacent(direction)
            actor.set_position(location, :internal, true)
            true
        else
            false
        end
    end
end

# TODO - We need to start dispatching messages when the AI is *about* to attack something
#   This way, the players have a basic idea of when they're in danger.  It's no fun to get attacked
#   by a guard without warning.
#   Incidentally, this also gives us a logical place to insert taunts and challenges.
Behavior.define(:attack) do |actor|
    # FIXME - We need a better way to determine if two parties should behave aggressively towards each other
    enemies = Behavior.enemies_in_area(actor)
    if attackee = enemies.first
        Log.debug("#{actor.monicker} is attacking #{attackee.monicker}", 5)
        actor.do_command(:command => :attack, :target => attackee)
        true
    else
        false
    end
end

# TODO - Discuss how this works for vampires and how to functionally represent that drinking blood is bad.
# Question: Can players / AI do things furtively / in secret?
Behavior.define(:consume) do |actor|
    consumable_type = actor.class_info[:consumes] || :consumable
    consumables = actor.filter_objects([:position, :grasped, :stashed], :type => consumable_type)
    consumables.reject! { |c| c == actor } # Make sure jikininki don't eat themselves :-p

    if consumables.empty?
        Log.debug("#{actor.monicker} finds nothing to consume", 6)
        false
    else
        consumable = consumables.first
        Log.warning("Oh dear, people almost certainly shouldn't eat themselves") if actor == consumable
        actor.do_command(:command => :consume, :target => consumable)
        true
    end
end

BehaviorSet.define(:flee_if_threatened, {0 => [:flee]})
BehaviorSet.define(:random_attack_and_move, {0 => [:attack], 1 => [:random_movement]})
BehaviorSet.define(:roam_and_consume, {0 => [:consume], 1 => [:random_movement]})
