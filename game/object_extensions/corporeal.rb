module Corporeal
    class << self
        def at_message(instance, message)
            case message.type
            when :unit_attacks
                if message.defender == instance
                    # This unit is being attacked and needs to be damaged or something
                end
            end
        end
    end
end
