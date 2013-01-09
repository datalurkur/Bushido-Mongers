module Position
    class << self
        def at_creation(instance, context, params)
            if context[:position]
                instance.set_position(context[:position])
            end
        end
    end

    attr_reader :position

    def set_position(position)
        Log.debug("Setting position of #{monicker} to #{position.monicker}", 6)
        Log.warning("WARNING: Position being set more than once for #{monicker}; this method is meant to be called during setup and never again; call \"move\" instead") unless @position.nil?
        @position = position
        @position.add_object(self)
    end

    def nil_position
        Log.debug("Clearing position of #{name}", 6)
        # This should only be called on a character object prior to saving
        # This is to avoid storing any instance-specific data in a saved character which may be ported to other instances
        raise "See comment at game/object_extensions/position.rb:19" unless is_type?(:character)
        @position.remove_object(self)
        @position = nil
    end
end
