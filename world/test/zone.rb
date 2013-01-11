require './util/basic'
require './world/zone'

Log.setup("Zone", "zonetest")

=begin

Designed to test connections across depths

root
 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
|a              |b01    |       |
|               |       |       |
|               |       |       |
|       X       |_ _ _ _|_ _ _ _|
|               |b00    |b10    |
|               |       |       |
|              >|<  X   |   X   |
|_ _ _ _ _V_ _ _|_ _ _ _|_ _ _V_|
|       | ^ |  >|<  |   |d11  ^ |
|       |_X_|_X_|_X_|_ _|       |
|       |   |   |   |   |   X   |
|_ _ _ _|_ _|_ _|_ _|_ _|_ _ _ _|
|       |       |       |       |
|       |       |       |       |
|       |       |       |       |
|_ _ _ _|_ _ _ _|_ _ _ _|_ _ _ _|

=end

c11_01 = ZoneLeaf.new("c11_01")
c11_01.connect_to(:north)

c11_11 = ZoneLeaf.new("c11_11")
c11_11.connect_to(:east)

c11 = ZoneContainer.new("c11", 2, 2)
c11.set_zone(0,1,c11_01)
c11.set_zone(1,1,c11_11)

b00 = ZoneLeaf.new("b00")
b00.connect_to(:west)

b10 = ZoneLeaf.new("b10")
b10.connect_to(:south)

b01 = ZoneLeaf.new("b01")

d01_01 = ZoneLeaf.new("d01_01")
d01_01.connect_to(:west)

d01 = ZoneContainer.new("d01", 2, 2)
d01.set_zone(0,1,d01_01)

d11 = ZoneLeaf.new("d11")
d11.connect_to(:north)

a = ZoneLeaf.new("a")
a.connect_to(:east)
a.connect_to(:south)

b = ZoneContainer.new("b", 2, 2)
b.set_zone(0,0,b00)
b.set_zone(1,0,b10)
b.set_zone(0,1,b01)

c = ZoneContainer.new("c", 2, 3)
c.set_zone(1,1,c11)

d = ZoneContainer.new("d", 2, 2)
d.set_zone(1,1,d11)
d.set_zone(0,1,d01)

root = ZoneContainer.new("root", 2, 4)
root.set_zone(0,1,a)
root.set_zone(1,1,b)
root.set_zone(0,0,c)
root.set_zone(1,0,d)

def assert(condition)
    raise "Assert failed" unless condition
end

puts "1) Check that Zones at the same depth connect accurately (b10 <-> d11)"
assert(b10.connected_leaf(:south) == d11)
assert(d11.connected_leaf(:north) == b10)

puts "2) Check that Zones with 1 depth difference connect accurately (a <-> b00)"
assert(a.connected_leaf(:east) == b00)
assert(b00.connected_leaf(:west) == a)

puts "3) Check that Zones with 2 depth difference connect accurately (a <-> c11_01)"
assert(a.connected_leaf(:south) == c11_01)
assert(c11_01.connected_leaf(:north) == a)

puts "4) Check that Leaves at a higher depth accurately get a list of Leaves they can connect to (a => b00,b01)"
assert([b00, b01].contents_equivalent?(a.connectable_leaves(:east)))

puts "5) Check that Leaves at a lower depth accurately get the Leaf they can connect to at a higher depth (b01 => a)"
assert(b00.connectable_leaves(:west) == [a])
assert(b01.connectable_leaves(:west) == [a])

puts "6) Check that Leaves at a low depth accurately get each other as Leaves (d01_01 <=> c11_11)"
assert(d01_01.connectable_leaves(:west) == [c11_11])
assert(c11_11.connectable_leaves(:east) == [d01_01])

puts "7) Check that Leaves adjacent to empty spaces successfully return an empty list of potential leaves"
assert(b01.connectable_leaves(:east) == [])
