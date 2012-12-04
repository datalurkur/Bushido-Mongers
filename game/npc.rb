require 'game/mob'
require 'ai/basic_behavior'

class NPC < Mob
    def initialize(name)
        super(name)

        @behavior = BehaviorSet.create(:random_attack_and_move)
    end

    def set_behavior(behavior)
        @behavior = BehaviorSet.create(behavior)
    end

    def tick
        @behavior.act(self)
    end

    def attack(target)
        Log.debug("#{name} attacking #{target.name}")
    end

    def process_message(message)
        case message.type
        when :tick
            tick
        else
            Log.debug("NPC #{@name} ignoring #{message.type}")
        end
    end
end
