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

        def at_creation(instance, params)
            instance.instance_exec {
                body_type = @core.db.info_for(@type, :body_type)
                body      = @core.db.create(@core, body_type, {:relative_size => @properties[:size]})
                @properties[:body]   = body
                @properties[:weight] = body.weight
            }
        end

        def at_destruction(instance)
        end
    end
end
