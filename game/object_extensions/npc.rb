require 'ai/basic_behavior'

module NpcBehavior
    class << self
        def at_creation(instance, params)
            instance.set_behavior(params[:behavior] || :random_attack_and_move)
        end

        def at_message(instance, message)
            case message.type
            when :tick
                instance.behavior.act(instance)
                return true
            end
            return false
        end
    end

    attr_accessor :behavior

    def set_behavior(behavior)
        @behavior = BehaviorSet.create(behavior)
    end

    def attack(target)
        Log.debug("#{name} attacking #{target.name}")
        Message.dispatch(@core, :unit_attacks, {
            :attacker      => self,
            :defender      => target,
            :chance_to_hit => "FIXME",
            :damage        => "FIXME"
        })
    end
end
