class Behavior
    class << self
        def criteria
            @criteria ||= {}
        end

        def actions
            @actions ||= {}
        end

        # <Symbol:behavior> is possible when <Proc:criteria> is met, and is defined by <Proc:action>
        def define(behavior, criterion=nil, &block)
            raise ArgumentError unless block_given?
            criteria[behavior] = criterion
            actions[behavior] = block
        end

        def criteria_met?(behavior, actor)
            if Symbol === criteria[behavior]
                return send(criteria[behavior], actor)
            elsif Proc === criteria[behavior]
                return criteria[behavior].call(actor)
            else
                return true
            end
        end

        def act(behavior, actor)
            unless actions.has_key?(behavior)
                raise ArgumentError, "#{behavior.inspect} not found in list of behaviors"
            end
            actions[behavior].call(actor)
        end

        def are_enemies_present?(actor)
            !enemies_present(actor).empty?
        end

        def enemies_present(actor)
            others  = actor.position.occupants - [actor]
            enemies = others.select { |other| are_enemies?(actor, other) }
        end

        def are_enemies?(actor_a, actor_b)
            # TODO - Make factions more complex
            (actor_a.factions & actor_b.factions).empty?
        end
    end
end
