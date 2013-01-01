module Corporeal
    class << self
        def at_message(instance, message)
            case message.type
            when :unit_attacks
                if message.defender == instance
                    Log.debug("#{instance.name} is being attacked!")
                    # This unit is being attacked and needs to be damaged or something
                end
            end
        end
    end
end
