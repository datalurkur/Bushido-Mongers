require 'world/world'

Log.setup("main thread", "world_test")

w = World.test_world_2
w.print_map("world_map.png")
