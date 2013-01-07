module Position
    class << self
        def at_creation(instance, context, params)
            instance.set_position(context[:position])
        end
    end

    attr_reader :position

    def set_position(position)
        Log.debug("Setting position of #{monicker} to #{position.name}", 6)
        Log.warning("WARNING: Position being set more than once for #{@name}; this method is meant to be called during setup and never again; call \"move\" instead") unless @position.nil?
        @position = position
        @position.add_object(self)
    end

    def nil_position
        Log.debug("Clearing position of #{name}", 6)
        # This should only be called on a character object prior to saving
        # This is to avoid storing any instance-specific data in a saved character which may be ported to other instances
        raise "See comment at game/object_extensions/mob.rb:22" unless is_a?(:character)
        @position.remove_object(self)
        @position = nil
    end

    def move(direction)
        raise Exception, "Position uninitialized" if @position.nil?

        # This method raises an exception if the direction is invalid, so no need to check it
        new_position = @position.connected_leaf(direction)

        Log.debug("#{monicker} moves from #{@position.name} to #{new_position.name}")
        @position.remove_object(self)
        @position = new_position
        @position.add_object(self)
    end
end
