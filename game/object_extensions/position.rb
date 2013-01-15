require './util/log'

module Position
    class << self
        def at_creation(instance, params)
            instance.set_position(params[:position], params[:position_type] || :internal) unless params[:position].nil?
        end

        def at_destruction(instance)
            if instance.has_position?
                instance.relative_position.remove_object(instance)
            else
                Log.warning(["Destroying object with no position - #{instance.monicker}", caller])
            end
        end
    end

    def has_position?
        !@position.nil?
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

    def set_position(position, type=:internal)
        Log.debug("Setting position of #{monicker} to #{position.monicker}", 6)
        unless @position.nil?
            Log.warning("WARNING: Position being set more than once for #{monicker}; this method is meant to be called during setup and never again; call \"move\" instead")
        end
        @position      = position
        @position_type = type
        @position.add_object(self, type)
    end

    def nil_position
        Log.debug("Clearing position of #{monicker}", 6)
        # This should only be called on a character object prior to saving
        # This is to avoid storing any instance-specific data in a saved character which may be ported to other instances
        raise "See comment at game/object_extensions/position.rb:19" unless is_type?(:character)
        @position.remove_object(self)
        @position      = nil
        @position_type = nil
    end

    def move_to(new_position)
        raise(Exception, "Position uninitialized for #{monicker}") if @position.nil?

        Log.debug("#{monicker} moved from #{@position.monicker} to #{new_position.monicker}")
        @position.remove_object(self)
        @position      = new_position
        @position_type = :internal
        @position.add_object(self)
    end

    def attach_to(object)
        raise(Exception, "Position uninitialized for #{monicker}") if @position.nil?

        Log.debug("#{monicker} attaches to #{object.monicker} (was in #{@position.monicker})")
        @position.remove_object(self)
        @position      = object
        @position_type = :external
        @position.attach_object(self)
    end

    private
    def safe_position
        unless has_position?
            Log.error(["Object with no position being queried for its position", caller])
            raise Exception
        end
    end
end
