require './util/log'
require './util/exceptions'
require './game/transforms'

module Corporeal
    class << self
        def at_creation(instance, params)
            raise(MissingObjectExtensionError, "Corporeal objects are required to be compositions") unless instance.uses?(Composition)
            instance.integrity = instance.all_body_parts.inject(0) { |s,p| s + p.integrity }
        end

        def at_destruction(instance, destroyer, vaporize)
            if instance.alive? && !vaporize
                instance.kill(destroyer)
            end
        end
    end

    def all_body_parts(type = [:internal, :external])
        [self] + select_objects(type, true) { |obj| obj.is_type?(:body_part) }
    end

    def external_body_parts
        all_body_parts(:external)
    end

    def internal_body_parts
        all_body_parts(:internal)
    end

    def damage(amount, attacker, target=nil)
        # If a body part (target) isn't specified, just damage the body.
        target ||= self
        target.integrity -= amount
        if target.integrity <= 0
            if target == self
                kill(attacker)
            else
                @core.flag_for_destruction(target, attacker)
            end
        end
    end

    def alive?
        uses?(Character) || uses?(NpcBehavior)
    end

    def kill(attacker)
        raise(StateError, "#{self.monicker} is already dead!") unless alive?
        if attacker == self
            Log.warning("Something just killed itself...yep, that's a bug.")
        end
        transform(:death, {:agent => attacker})
    end
end
