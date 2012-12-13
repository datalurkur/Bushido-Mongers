#!/usr/bin/ruby

require 'world/factories'

Log.setup("main thread", "factory_test")

world = WorldFactory.generate(2, 2)
world.print_map("generated_world.png")
world.check_consistency
