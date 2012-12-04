require 'behavior'

class BehaviorSet
    class << self
        def behavior_sets
            @behavior_sets ||= {}
        end

        def define(id, behavior_set)
            behavior_sets[id] = behavior_set
        end

        def create(id)
            BehaviorSet.new(behavior_sets[id])
        end
    end

    def initialize(behavior_set)
        raise ArgumentError unless Hash === behavior_set
        @bset = behavior_set
    end

    def behavior_set
        @behavior_set ||= {}
    end

    def priorities
        @behavior_set.keys
    end

    def add_behavior(behavior, p)
        behavior_set[p] ||= []
        behavior_set[p] << behavior
    end

    def remove_behavior(behavior, p)
        behavior_set[p].delete(behavior)
        behavior_set.delete(p) if behavior_set[p].empty?
    end

    def act(actor)
        acted = false
        priorities.sort.each do |priority|
            Log.debug("Checking priority #{priority} behaviors")
            behavior_set[priority].each do |behavior|
                Log.debug("Determining eligibility of #{behavior}")
                next unless Behavior.criteria_met?(behavior, actor)
                Log.debug("Criteria met")
                if Behavior.act(behavior, actor)
                    Log.debug("Action taken")
                    acted = true
                    break
                else
                    Log.debug("No action taken")
                end
            end
            break if acted
        end
    end
end
