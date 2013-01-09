module Corporeal
    class << self
        def at_message(instance, message)
            instance.instance_exec {
                case message.type
                when :unit_attacks
                    if message.defender == self
                        Log.debug("#{monicker} is being attacked!")
                        # This unit is being attacked and needs to be damaged or something
                        # FIXME - Actually do damage rather than just destroying the thing
                        Message.dispatch(@core, :object_destroyed, {:agent => message.attacker, :position => @position, :target => self})
                        self.destroy
                    end
                end
            }
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
            # Drop the body
            instance.instance_exec {
                @properties[:body].set_position(@position)
            }
        end
    end
end
