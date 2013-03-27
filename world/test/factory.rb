require './world/factories'
require './test/fake'

Log.setup("Main", "factory_test")

world = WorldFactory.generate(CoreWrapper.new, {:size => 5, :depth => 3})
world.check_consistency
world.get_map_layout(512, 0.2)
