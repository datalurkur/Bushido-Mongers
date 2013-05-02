require './raws/db'
require './game/object_extensions'
require './game/tables'
require './test/fake'
Log.setup("Main", "test")
#Log.disable_channel(:debug)

core = CoreWrapper.new
body_type = :fox

Log.debug("Creating #{body_type}")
test_body = core.create_npc(body_type, {:name => "Kenji Skrimshank", :position => FakeRoom.new})
Log.debug(["Test body", test_body])
Log.debug(["Layout", test_body.composition_layout])
Log.debug("Test body is called #{test_body.monicker}")
test_body.kill(nil)
Log.debug("Test body is called #{test_body.monicker}")
test_body.destroy(nil)
