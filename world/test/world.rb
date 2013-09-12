require './world/world'
require './test/fake'

Log.setup("Main", "world_test")

$c = FakeCore.new

def test_world
    # d---c
    #     |
    # a---b

    a = $c.create(Room, {:name => "a"})
    a.connect_to(:east)

    b = $c.create(Room, {:name => "b"})
    b.connect_to(:west)
    b.connect_to(:north)

    c = $c.create(Room, {:name => "c"})
    c.connect_to(:south)
    c.connect_to(:west)

    d = $c.create(Room, {:name => "d"})
    d.connect_to(:east)

    world = $c.create(World, {:name => "Test World", :size => 2, :depth => 2})
    world.set_zone(0,0,a)
    world.set_zone(1,0,b)
    world.set_zone(1,1,c)
    world.set_zone(0,1,d)

    world.check_consistency
    world.finalize
    world
end

def test_world_2
    c11_01 = $c.create(Room, {:name => "c11_01"})
    c11_01.connect_to(:north)

    c11 = $c.create(Area, {:name => "c11", :size => 2, :depth => 2})
    c11.set_zone(0,1,c11_01)

    b00 = $c.create(Room, {:name => "b00"})
    b00.connect_to(:west)

    b10 = $c.create(Room, {:name => "b10"})
    b10.connect_to(:south)

    b01 = $c.create(Room, {:name => "b01"})

    d11 = $c.create(Room, {:name => "d11"})
    d11.connect_to(:north)

    a = $c.create(Room, {:name => "a"})
    a.connect_to(:east)
    a.connect_to(:south)

    b = $c.create(Area, {:name => "b", :depth => 2, :size => 2})
    b.set_zone(0,0,b00)
    b.set_zone(1,0,b10)
    b.set_zone(0,1,b01)

    c = $c.create(Area, {:name => "c", :depth => 3, :size => 2})
    c.set_zone(1,1,c11)

    d = $c.create(Area, {:name => "d", :depth => 2, :size => 2})
    d.set_zone(1,1,d11)

    world = $c.create(World, {:name => "world", :size => 2, :depth => 4})
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
