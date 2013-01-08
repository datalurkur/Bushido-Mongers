class Behavior
    class << self
        def actions
            @actions ||= {}
        end

        # <Symbol:behavior> is possible when <Proc:criteria> is met, and is defined by <Proc:action>
        def define(behavior, &block)
            raise ArgumentError unless block_given?
            actions[behavior] = block
        end

        def act(behavior, actor)
            unless actions.has_key?(behavior)
                raise ArgumentError, "#{behavior.inspect} not found in list of behaviors"
            end
            actions[behavior].call(actor)
        end

        def are_enemies?(actor_a, actor_b)
            # TODO - Make factions more complex
            (actor_a.factions & actor_b.factions).empty?
        end
    end
end
