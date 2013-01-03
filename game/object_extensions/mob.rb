module Mob
    class << self
        def at_creation(instance, params)
            SharedObjectExtensions.check_required_params(params, [:initial_position])
            instance.set_position(params[:initial_position])
        end
    end

    attr_reader :position

    def set_position(position)
        Log.debug("Setting position of #{name} to #{position.name}", 6)
        unless @position.nil?
            Log.warning("WARNING: Position being set more than once for #{@name}; this method is meant to be called during setup and never again")
        end
        @position = position
        @position.add_occupant(self)
    end

    def move(direction)
        raise Exception, "Position uninitialized" if @position.nil?
        new_position = @position.connected_leaf(direction)
        if new_position
            Log.debug("#{self.name} moves from #{@position.name} to #{new_position.name}")
            @position.remove_occupant(self)
            @position = new_position
            @position.add_occupant(self)
            return nil
        else
            return :path_blocked
        end
    end
end
