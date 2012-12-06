class Mob
    attr_reader :name, :position
    
    def initialize(name)
        @name = name
    end

    def set_position(position)
        unless @position.nil?
            Log.warning("WARNING: Position begin set more than once for #{@name}; this method is meant to be called during setup and never again")
        end
        @position = position
        @position.add_occupant(self)
    end

    def move(direction)
        raise Exception, "Position uninitialized" if @position.nil?
        new_position = @position.connected_leaf(direction)
        if new_position
            Log.debug("#{@name} moves from #{@position.name} to #{new_position.name}")
            @position.remove_occupant(self)
            @position = new_position
            @position.add_occupant(self)
            return nil
        else
            return :path_blocked
        end
    end
end