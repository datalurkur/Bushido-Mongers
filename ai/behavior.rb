class Behavior
    class << self
        def criteria
            @criteria ||= {}
        end

        def actions
            @actions ||= {}
        end

        # <Symbol:behavior> is possible when <Proc:criteria> is met, and is defined by <Proc:action>
        def define(behavior, criteria=nil, &block)
            raise ArgumentError unless block_given?
            @criteria[behavior] = criteria
            @actions[behavior] = block
        end

        def criteria_met?(behavior, actor)
            raise ArgumentError unless @critera.has_key?(behavior)
            if @criteria[behavior]
                return @criteria[behavior].call(actor)
            else
                return true
            end
        end

        def perform_behavior(behavior, actor)
            raise ArgumentError unless @critera.has_key?(behavior)
            @actions[behavior].call(actor)
        end
    end
end

# Using inheritance as a means of scoping behaviors, if this ever becomes necessary
class NPCBehavior < Behavior
    class << self
        def are_enemies_present?(actor)
            !enemies_present(actor).empty?
        end

        def enemies_present(actor)
            others  = actor.position.occupants - [actor]
            enemies = others.select { |other| are_enemies?(actor, other) }
        end

        def are_enemies?(actor_a, actor_b)
            if NPC === actor_a && NPC === actor_b
                # TODO - Faction stuff goes here
                return true
            else
                return true
            end
        end
    end
end
