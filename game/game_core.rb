require 'world/world'
require 'game/player'

class GameCore
    attr_reader :world
    def initialize(args={})
        @world   = World.test_world
    end
end
