require './util/log'

module Position
    class << self
        def at_creation(instance, params)
            instance.set_position(params[:position], params[:position_type] || :internal) unless params[:position].nil?
        end

        def at_destruction(instance)
            instance.position.remove_object(instance) unless instance.position.nil?
        end
    end

    attr_reader :position

    def set_position(position, type=:internal)
        Log.debug("Setting position of #{monicker} to #{position.monicker}", 6)
        unless @position.nil?
            Log.warning("WARNING: Position being set more than once for #{monicker}; this method is meant to be called during setup and never again; call \"move\" instead")
        end
        @position = position
        @position.add_object(self, type)
    end

    def nil_position
        Log.debug("Clearing position of #{name}", 6)
        # This should only be called on a character object prior to saving
        # This is to avoid storing any instance-specific data in a saved character which may be ported to other instances
        raise "See comment at game/object_extensions/position.rb:19" unless is_type?(:character)
        @position.remove_object(self)
        @position = nil
    end

    def move(direction)
        raise Exception, "Position uninitialized for #{monicker}" if @position.nil?

        # This method raises an exception if the direction is invalid, so no need to check it
        new_position = @position.get_adjacent(direction)

        Log.debug("#{monicker} moves from #{@position.name} to #{new_position.name}")
        @position.remove_object(self)
        @position = new_position
        @position.add_object(self)
    end
end
