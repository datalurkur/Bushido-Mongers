#!/usr/bin/ruby

require './world/factories'

Log.setup("Main", "factory_test")

world = WorldFactory.generate(5, 3)
world.print_map("generated_world.png")
world.check_consistency
