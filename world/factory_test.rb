require 'world/factories'

Log.setup("main thread", "factory_test")

world = WorldFactory.generate(5, 4)
world.print_map("generated_world.png")
world.check_consistency
