require 'world/world'
require 'math/noise'

class WorldFactory
class << self
    def generate(size, depth, config={})
        generate_area(size, depth, config[:openness], config[:connectedness])
    end

    def generate_area(size, depth, openness, connectedness, parent_area=nil)
        noise_size = (size * 3) - 1
    end
end
end
