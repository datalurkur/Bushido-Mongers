require './util/log'

module Karmic
    class << self
        def at_creation(instance, params)
            instance.set_property(:name, params[:name])
        end

        def at_message(instance, message)
            case message.type
            when :object_destroyed
                return unless message.agent == instance
                if message.target.is_type?(:corporeal)
                    # FIXME - We want to store more than the name of the kill here
                    # Suggestions - notoriety / difficulty of kill, type of monster
                    instance.kills << message.target.monicker
                    Log.info("#{instance.monicker} increases their notoriety by shedding the blood of #{message.target.monicker} (now has #{instance.kills.size} kills)")
                end
            end
        end

        def at_destruction(instance)
            # FIXME - Create a notoriety table
            #if instance.notoriety >= :well_known
                Log.info("The great #{instance.monicker} has been slain!")
            #end
        end
    end
end
