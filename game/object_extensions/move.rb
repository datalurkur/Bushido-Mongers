module Move
    def move(direction)
        raise Exception, "Position uninitialized; is #{self.name} positionable?" if @position.nil?

        # This method raises an exception if the direction is invalid, so no need to check it
        new_position = @position.connected_leaf(direction)

        Log.debug("#{monicker} moves from #{@position.name} to #{new_position.name}")
        @position.remove_object(self)
        @position = new_position
        @position.add_object(self)
    end
end