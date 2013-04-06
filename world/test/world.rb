require './world/world'
require './test/fake'

Log.setup("Main", "world_test")

$c = CoreWrapper.new

def test_world
    # d---c
    #     |
    # a---b

    a = Room.new($c, "a")
    a.connect_to(:east)

    b = Room.new($c, "b")
    b.connect_to(:west)
    b.connect_to(:north)

    c = Room.new($c, "c")
    c.connect_to(:south)
    c.connect_to(:west)

    d = Room.new($c, "d")
    d.connect_to(:east)

    world = World.new($c, "Test World", 2, 2)
    world.set_zone(0,0,a)
    world.set_zone(1,0,b)
    world.set_zone(1,1,c)
    world.set_zone(0,1,d)

    world.check_consistency
    world.finalize
    world
end

def test_world_2
    c11_01 = Room.new($c, "c11_01")
    c11_01.connect_to(:north)

    c11 = Area.new($c, "c11", 2, 2)
    c11.set_zone(0,1,c11_01)

    b00 = Room.new($c, "b00")
    b00.connect_to(:west)

    b10 = Room.new($c, "b10")
    b10.connect_to(:south)

    b01 = Room.new($c, "b01")

    d11 = Room.new($c, "d11")
    d11.connect_to(:north)

    a = Room.new($c, "a")
    a.connect_to(:east)
    a.connect_to(:south)

    b = Area.new($c, "b", 2, 2)
    b.set_zone(0,0,b00)
    b.set_zone(1,0,b10)
    b.set_zone(0,1,b01)

    c = Area.new($c, "c", 2, 3)
    c.set_zone(1,1,c11)

    d = Area.new($c, "d", 2, 2)
    d.set_zone(1,1,d11)

    world = World.new($c, "world", 2, 4)
    world.set_zone(0,1,a)
    world.set_zone(1,1,b)
    world.set_zone(0,0,c)
    world.set_zone(1,0,d)

    world.check_consistency
    world.finalize
    world
end

w = test_world_2
png_data = w.get_map_layout(512, 0.2)
