require './util/log'
require './util/exceptions'
require './game/transforms'

module Corporeal
    class << self
        def listens_for(i); [:object_destroyed]; end

        def at_creation(instance, params)
            raise(MissingObjectExtensionError, "Corporeal objects are required to be compositions") unless instance.uses?(Composition)
        end

        def at_message(instance, message)
            # FIXME - Check to see if vital organs are being destroyed
        end

        def at_destruction(instance, destroyer, vaporize)
            if instance.alive? && !vaporize
                instance.kill(destroyer)
            end
        end
    end

    def find_body_parts(type)
        all_body_parts.select { |p| p.get_type == type }
    end
    def all_body_parts(type = [:internal, :external])
        [self] + select_objects(type, true) { |obj| obj.is_type?(:body_part) }
    end
    def external_body_parts; all_body_parts(:external); end
    def internal_body_parts; all_body_parts(:internal); end

    def alive?
        uses?(Character) || uses?(NpcBehavior)
    end

    def kill(attacker)
        raise(StateError, "#{self.monicker} is already dead!") unless alive?
        if attacker == self
            Log.warning("Something just killed itself...yep, that's a bug.")
        end
        transform(:kill, {:agent => attacker})
    end
end
