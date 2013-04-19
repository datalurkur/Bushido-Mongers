require './util/log'
require './util/exceptions'

module Position
    class << self
        def at_creation(instance, params)
            instance.set_position(params[:position], params[:position_type] || :internal) if params[:position]
        end

        def at_destruction(instance, destroyer, vaporize)
            if instance.has_position?
                instance.dispatch_destruction_message(destroyer) unless vaporize
                instance.relative_position.component_destroyed(instance, instance.relative_position_type, destroyer)
            else
                Log.warning(["Destroying object with no position - #{instance.monicker}", caller])
            end
        end
    end

    def dispatch_destruction_message(destroyer)
        if has_position?
            Message.dispatch_positional(@core, [absolute_position], :object_destroyed, {
                :agent    => destroyer,
                :location => absolute_position,
                :target   => self
            })
        end
    end

    def has_position?
        !!@position
    end

    def absolute_position
        safe_position
        obj = self
        while obj.relative_position_type != :internal
            obj = obj.relative_position
        end
        return obj.relative_position
    end

    # The corporeal that possesses the object
    def possessive_position
        obj = self
        until (obj.relative_position_type == :internal && obj.uses?(Corporeal) && obj.alive?)
            obj = obj.relative_position
            break unless (BushidoObject === obj)
        end
        return (BushidoObject === obj) ? obj : nil
    end

    # The position of the construct/composition that includes this object
    def unit_position
        obj = self
        while obj.relative_position_type != :internal
            obj = obj.relative_position
        end
        return obj
    end

    def relative_position
        safe_position
        @position
    end

    def relative_position_type
        safe_position
        @position_type
    end

    def set_position(new_position, position_type, locomotes=false)
        message_type = locomotes ? :unit_moves : :unit_moved
        locations    = [@position, new_position].compact
        Message.dispatch_positional(@core, locations, message_type, {
            :agent       => self,
            :action      => :move,
            :origin      => @position,
            :destination => new_position
        })
        Message.change_listener_position(@core, self, new_position, @position)
        @position.remove_object(self, @position_type) if @position
        @position      = new_position
        @position_type = position_type
        @position.add_object(self, @position_type)
    end

    def safe_position
        raise UnexpectedBehaviorError, "#{self.monicker} (#{self.get_type}) has no position!" unless has_position?
    end
end
