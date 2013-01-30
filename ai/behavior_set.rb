require './ai/behavior'

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
        raise(ArgumentError, "Expected Hash, received #{behavior_set.class}") unless Hash === behavior_set
        @behavior_set = behavior_set
    end

    def priorities
        @behavior_set.keys
    end

    def add_behavior(behavior, p)
        @behavior_set[p] ||= []
        @behavior_set[p] << behavior
    end

    def remove_behavior(behavior, p)
        @behavior_set[p].delete(behavior)
        @behavior_set.delete(p) if @behavior_set[p].empty?
    end

    def act(actor)
        acted = false
        priorities.sort.each do |priority|
            @behavior_set[priority].each do |behavior|
                if Behavior.act(behavior, actor)
                    acted = true
                    break
                end
            end
            break if acted
        end
    end
end
