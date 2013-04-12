require './util/log'
require './util/exceptions'

module Position
    class << self
        def at_creation(instance, params)
            instance.set_initial_position(params[:position], params[:position_type] || :internal) unless params[:position].nil?
        end

        def at_destruction(instance, destroyer, vaporize)
            if instance.has_position?
                instance.dispatch_destruction_message(destroyer) unless vaporize
                instance.relative_position.destroy_object(instance, destroyer)
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

        case @position_type
        when :internal
            @position
        else
            @position.absolute_position
        end
    end

    def relative_position
        safe_position

        @position
    end

    def set_initial_position(position, type=:internal)
        Log.debug("Setting position of #{monicker} to #{position.monicker}", 6)
        if @position
            Log.warning("WARNING: Position being set more than once for #{monicker}; this method is meant to be called during setup and never again; call \"move_to\" instead")
        end
        Message.change_listener_position(@core, self, position, @position)
        @position      = position
        @position_type = type
        @position.add_object(self, type, false)
    end

    # destination is assumed to be a room
    # n.b. doesn't remove the item from the old position
    def drop(destination)
        Log.debug("#{monicker} dropped from #{@position.monicker} to #{destination.monicker}", 5)

        Message.dispatch_positional(@core, [destination], :unit_acts, {
            :agent         => self,
            :action        => :drop,
            :location      => destination,
            :action_hash   => { :destination => destination.zone_info[:ground_name] }
        })

        @position      = nil # avoid removing the object from the old position
        _set_position(destination)
        @position_type = :internal
        @position.add_object(self)
    end

    def grasped_by(new_position)
        Log.debug("#{monicker} grasped by #{new_position.monicker}", 5)
        _set_position(new_position)
        @position_type = :grasped
        @position.add_object(self, :grasped)
    end

    def equip_on(new_position)
        Log.debug("#{monicker} equipped on #{new_position.monicker}", 5)
        _set_position(new_position)
        @position_type = :worn
        @position.add_object(self, :worn)
    end

    def incorporate_into(new_position)
        Log.debug("#{monicker} incorporated into #{new_position.monicker}", 5)
        _set_position(new_position)
        @position_type = :incidental
        @position.add_object(self, :incidental, false)
    end

    def move_to(destination, direction = nil)
        Log.debug("#{monicker} moved to #{destination.monicker} with direction #{direction}", 5)

        # FIXME - This is actually a determination of whether something locomotes or *is moved*
        # FIXME - Shouldn't print messages for hidden moving things
        if self.uses?(Corporeal) && self.alive?
            origin = self.absolute_position
            msg_args =
            {
                :agent         => self,
                :action        => :move,
                :origin        => origin,
                :destination   => destination
            }
            msg_args[:direction] = direction if direction
            Message.dispatch_positional(@core, [origin, destination], :unit_moves, msg_args)
        end

        _set_position(destination)
        @position_type = :internal
        @position.add_object(self)
    end

    def attach_to(new_position)
        Log.debug("#{monicker} attached to #{new_position.monicker}", 5)
        _set_position(new_position)
        @position_type = :external
        @position.add_object(self, :external)
    end

    private
    def _set_position(new_position)
        Message.change_listener_position(@core, self, new_position, @position)
        @position.remove_object(self) if @position
        @position = new_position
    end

    def safe_position
        raise UnexpectedBehaviorError, "#{self.monicker} (#{self.get_type}) has no position!" unless has_position?
    end
end
