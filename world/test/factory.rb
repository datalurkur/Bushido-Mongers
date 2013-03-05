require './world/factories'
require './test/fake'
require './raws/db'

Log.setup("Main", "factory_test")

db = ObjectDB.get("default")

world = WorldFactory.generate(FakeCore.new(db), {:size => 5, :depth => 3})
world.check_consistency
world.get_map_layout(512, 0.2)
