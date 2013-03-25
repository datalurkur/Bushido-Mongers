require './util/log'
require './util/exceptions'
require './game/transforms'

module Corporeal
    class << self
        def at_creation(instance, params)
            raise(MissingObjectExtensionError, "Corporeal objects are required to be compositions") unless instance.uses?(Composition)
            instance.animate
        end
    end

    def animate
        @properties[:total_hp] = all_body_parts.inject(0) { |s,p| s + p.properties[:hp] }
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
        target.properties[:hp] -= amount
        @properties[:total_hp] -= amount
        if target.properties[:hp] <= 0
            if target == self
                kill(attacker)
            else
                @core.flag_for_destruction(target, attacker)
            end
        end
    end

    def kill(attacker)
        Log.debug("Killing #{monicker}!")
        transform(:death, {:agent => attacker})
    end
end
