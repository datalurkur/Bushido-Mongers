require 'raws/db'

Log.setup("main thread", "test")

db = ObjectDB.new("default")
Log.debug(["DB", db.db])
