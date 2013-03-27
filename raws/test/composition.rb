require './raws/db'
require './game/object_extensions'
require './game/tables'
require './test/fake'
Log.setup("Main", "test")
#Log.disable_channel(:debug)

# Basic DB parsing tests
raw_group = "default"
Log.debug("Creating object DB")
db = ObjectDB.get(raw_group)
core = FakeCore.new(db)

Log.debug("Creating character")
test_body = core.create(:human, {:name => "Test Character", :position => FakeRoom.new})
Log.debug("Test body is called #{test_body.monicker}")
test_body.kill(nil)
Log.debug("Test body is called #{test_body.monicker}")
test_body.destroy(nil)
