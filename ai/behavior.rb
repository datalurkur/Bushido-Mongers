class Behavior
    class << self
        def actions
            @actions ||= {}
        end

        # <Symbol:behavior> is possible when <Proc:criteria> is met, and is defined by <Proc:action>
        def define(behavior, &block)
            raise(ArgumentError, "No block given for behavior definition.")  unless block_given?
            actions[behavior] = block
        end

        def act(behavior, actor)
            unless actions.has_key?(behavior)
                raise(ArgumentError, "#{behavior.inspect} not found in list of behaviors")
            end
            actions[behavior].call(actor)
        end

        def enemies_in_area(actor)
            potential_enemies = actor.filter_objects(:position, :uses => Perception)
            potential_enemies.delete(actor)
            enemies = potential_enemies.select { |npc| Behavior.are_enemies?(npc, actor) }
        end

        # FIXME - We need a better way to determine if two parties should behave aggressively towards each other
        def are_enemies?(actor_a, actor_b)
            # TODO - Make faction interactions more complex
            (actor_a.factions.keys & actor_b.factions.keys).empty?
        end
    end
end
