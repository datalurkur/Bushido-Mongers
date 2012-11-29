require 'util/basic'
require 'world/room'
require 'graphics/png'

class World < Area
    def initialize(name, size, max_depth)
        super(name, size, max_depth)
    end

    def starting_locations
        @starting_locations ||= []
    end

    def add_starting_location(location)
        starting_locations << location
    end

    def random_starting_location
        starting_locations.rand
    end

    def print_map(filename, cell_size=20, corridor_size=4)
        cells_per_side = @size ** (@depth - 1)
        png_size  = cell_size * cells_per_side
        Log.debug("Printing a map of the world with cell size #{cell_size}, size / depth of #{@size} / #{@depth} (#{cells_per_side} cells per side), and a png size of #{png_size}")
        png = DerpyPNG.new(png_size, png_size)
        draw_to_png(png, png_size, corridor_size)
        png.save(filename)
    end

    def self.test_world
        # d---c
        #     |
        # a---b

        a = Room.new("a")
        a.connect_to(:east)

        b = Room.new("b")
        b.connect_to(:west)
        b.connect_to(:north)

        c = Room.new("c")
        c.connect_to(:south)
        c.connect_to(:west)

        d = Room.new("d")
        d.connect_to(:east)

        world = World.new("Test World", 4, 4)
        world.set_zone(0,0,a)
        world.set_zone(1,0,b)
        world.set_zone(1,1,c)
        world.set_zone(0,1,d)

        world.add_starting_location(d.get_full_coordinates)
        world.check_consistency
        world
    end

    def self.test_world_2
        c11_01 = Room.new("c11_01")
        c11_01.connect_to(:north)

        c11 = Area.new("c11", 2, 2)
        c11.set_zone(0,1,c11_01)

        b00 = Room.new("b00")
        b00.connect_to(:west)

        b10 = Room.new("b10")
        b10.connect_to(:south)

        b01 = Room.new("b01")

        d11 = Room.new("d11")
        d11.connect_to(:north)

        a = Room.new("a")
        a.connect_to(:east)
        a.connect_to(:south)

        b = Area.new("b", 2, 2)
        b.set_zone(0,0,b00)
        b.set_zone(1,0,b10)
        b.set_zone(0,1,b01)

        c = Area.new("c", 2, 3)
        c.set_zone(1,1,c11)

        d = Area.new("d", 2, 2)
        d.set_zone(1,1,d11)

        world = World.new("world", 2, 4)
        world.set_zone(0,1,a)
        world.set_zone(1,1,b)
        world.set_zone(0,0,c)
        world.set_zone(1,0,d)

        world.add_starting_location(c11_01.get_full_coordinates)
        world.check_consistency
        world
    end
end
