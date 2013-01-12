require './world/factories'
require './test/fake'
require './raws/db'

Log.setup("Main", "factory_test")

db = ObjectDB.get("default")

world = WorldFactory.generate({:core => FakeCore.new(db), :size => 5, :depth => 3})
world.check_consistency
world.get_map
