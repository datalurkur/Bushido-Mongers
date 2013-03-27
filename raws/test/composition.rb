require './raws/db'
require './game/object_extensions'
require './game/tables'
require './test/fake'
Log.setup("Main", "test")
#Log.disable_channel(:debug)

core = CoreWrapper.new

Log.debug("Creating human")
test_body = core.create_agent(:human, true, {:name => "Kenji Skrimshank", :position => FakeRoom.new})
Log.debug("Test body is called #{test_body.monicker}")
test_body.kill(nil)
Log.debug("Test body is called #{test_body.monicker}")
test_body.destroy(nil)
