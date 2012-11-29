require 'math/noise'
require 'graphics/png'

class NoiseMap
    def initialize(size)
        @size  = size
        @noise = Noise.new
        @map   = Array.new(size) { Array.new(size) }

        @populated = false
        @min       = nil
        @max       = nil
    end

    def populate(granularity = (1.0 / 2.0**6))
        raise "You probably want granularity to be a float" unless Float === granularity
        dimension_scalar = @size / (@noise.noise_size * granularity)
        raise "You probably don't want to scale your dimensions by #{dimension_scalar}, try a granularity in the range (0.0, 1.0]" if dimension_scalar == 0.0
        (0...@size).each do |x|
            (0...@size).each do |y|
                scaled_x = x / dimension_scalar
                scaled_y = y / dimension_scalar
                @map[x][y] = @noise.perlin3(scaled_x, scaled_y, 0.5)
            end
        end
        @min = @map.collect(&:min).min
        @max = @map.collect(&:max).max
        @populated = true
    end

    def max
        raise "NoiseMap not populated" unless @populated
        @max
    end

    def min
        raise "NoiseMap not populated" unless @populated
        @min
    end

    def get(x, y)
        raise "NoiseMap not populated" unless @populated
        @map[x][y]
    end

    def get_scaled(x, y, new_min, new_max)
        raise "NoiseMap not populated" unless @populated
        preshrunk_range = (@max - @min)
        shrunk = if preshrunk_range == 0
            0.0
        else
            (get(x,y) - @min) / (@max - @min)
        end
        scaled = (shrunk * (new_max - new_min)) + new_min
        if Fixnum === new_min && Fixnum === new_max
            scaled.to_i
        else
            scaled
        end
    end

    def save_to_png(filename)
        png = DerpyPNG.new(@size, @size)
        (0...@size).each do |x|
            (0...@size).each do |y|
                value = get_scaled(x, y, 0, 255)
                png.index_and_set(x, y, value, value, value)
            end
        end
        png.save(filename)
    end
end
