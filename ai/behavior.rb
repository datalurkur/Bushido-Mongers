class Behavior
    class << self
        def criteria
            @criteria ||= {}
        end

        def actions
            @actions ||= {}
        end

        # <Symbol:behavior> is possible when <Proc:criteria> is met, and is defined by <Proc:action>
        def define(behavior, critera, action)
            @criteria[behavior] = criteria
            @actions[behavior] = action
        end

        # I'm kind of assuming that "state" is going to be room_info, but named it "state" in case we decide to change that later
        def criteria_met?(behavior, state)
            raise ArgumentError unless @critera.has_key?(behavior)
            if @criteria[behavior]
                @criteria[behavior].call(state)
            else
                true
            end
        end

        def perform_behavior(behavior, state)
            raise ArgumentError unless @critera.has_key?(behavior)
            @actions[behavior].call(state)
        end
    end
end
