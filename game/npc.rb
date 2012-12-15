require 'game/mob'
require 'ai/basic_behavior'
require 'raws/db'

class NPC < BushidoObject
    include Mob
    def initialize(name, type, db, args={})
        @name = name
        super(type, db, args)

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
