require 'world/world'

class GameCore
    def initialize(args={})
        @world   = World.test_world
        @players = []
    end
end
