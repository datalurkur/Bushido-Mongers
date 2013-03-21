require './raws/db'
require './game/tables'
require './game/object_extensions'
require './test/fake'
Log.setup("Main", "test")
Log.disable_channel(:debug)

# Basic DB parsing tests
raw_group = "default"
db = ObjectDB.get(raw_group)
core = FakeCore.new(db)

types = db.types_of(:body)
types.each do |body|
    test_body = core.create(body, {:position => FakeRoom.new, :relative_size => :medium})
    Log.debug(test_body)
    test_body.destroy(nil)
end
Log.debug(db.info_for(:arachnoid_body, :symmetric))
