require './test/fake'
require './raws/db'

Log.setup("Main", "db_sandbox")

db   = ObjectDB.get("default")
core = FakeCore.new(db)

while (str = gets)
    ret = eval str
    puts ret.inspect
end
