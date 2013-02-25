require './util/log'
require './util/exceptions'

module Position
    class << self
        def at_creation(instance, params)
            instance.set_position(params[:position], params[:position_type] || :internal) unless params[:position].nil?
        end

        def at_destruction(instance, destroyer, vaporize)
            if instance.has_position?
                instance.relative_position.remove_object(instance)
                instance.dispatch_destruction_message(destroyer) unless vaporize
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

    def set_position(position, type=:internal, force_set=false)
        Log.debug("Setting position of #{monicker} to #{position.monicker}", 6)
        if @position && !force_set
            Log.warning("WARNING: Position being set more than once for #{monicker}; this method is meant to be called during setup and never again; call \"move_to\" instead")
        end
        Message.change_listener_position(@core, self, position, @position)
        @position      = position
        @position_type = type
        @position.add_object(self, type)
    end

    def get_position
        [@position, @position_type]
    end

    def nil_position
        Log.debug("Clearing position of #{monicker}", 6)
        # This should only be called on a character object prior to saving
        # This is to avoid storing any instance-specific data in a saved character which may be ported to other instances
        raise(UnexpectedBehaviorError) unless is_type?(:character)
        Message.clear_listener_position(@core, self, @position)
        @position.remove_object(self)
        @position      = nil
        @position_type = nil
    end

    # HELPER FUNCTIONS for different position types.
    # TODO - make generators for these functions.

    def grasped_by(new_position)
        Log.debug("#{monicker} grasped by #{new_position.monicker}", 5)
        _set_position(new_position)
        @position_type = :grasped
        @position.grasp(self)
    end

    def equip_on(new_position)
        Log.debug("#{monicker} equipped on #{new_position.monicker}", 5)
        _set_position(new_position)
        @position_type = :worn
        @position.wear(self)
    end

    def move_to(destination)
        Log.debug("#{monicker} moved to #{destination.monicker}", 5)

        locations = [self.absolute_position, destination]
        Message.dispatch_positional(@core, locations, :unit_moves, {
            :agent         => self,
            :action        => :move,
            :location      => self.absolute_position,
            :destination   => destination
        })

        _set_position(destination)
        @position_type = :internal
        @position.add_object(self)
    end

    def attach_to(new_position)
        Log.debug("#{monicker} attached to #{new_position.monicker}", 5)
        _set_position(new_position)
        @position_type = :external
        @position.attach_object(self)
    end

    private
    def _set_position(new_position)
        Message.change_listener_position(@core, self, new_position, @position)
        @position.remove_object(self) if @position
        @position = new_position
    end

    def safe_position
        raise(UnexpectedBehaviorError) unless has_position?
    end
end
