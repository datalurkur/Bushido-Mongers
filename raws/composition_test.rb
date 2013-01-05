require 'raws/db'
require 'game/tables'
require 'game/object_extensions'
require 'test/fake'
Log.setup("Main", "test")

# Basic DB parsing tests
raw_group = "default"
db = ObjectDB.get(raw_group)
core = FakeCore.new(db)

test_body = db.create(core, :humanoid_body, {:relative_size => :medium})
Log.debug(test_body)
test_body.destroy
