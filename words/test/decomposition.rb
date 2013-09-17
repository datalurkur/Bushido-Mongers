require './util/log'
require './util/basic'
require './util/timer'

Log.setup("Vocabulary Test", "wordtest")

require './raws/db'
db = ObjectDB.get('default')
require './words/words'

words_db = WordParser.load
# And finally read in some basic noun & adjective information from the raws db.
WordParser.read_raws(words_db, db)

args = words_db.decompose_command("aTTack Spider")
Log.debug(args)
raise unless args[:command] == :attack
raise unless args[:target] == :spider

args = words_db.decompose_command("strike spider")
Log.debug(args)
raise unless args[:command] == :attack
raise unless args[:target] == :spider

args = words_db.decompose_command("spawn gold")
Log.debug(args)
raise unless args[:command] == :spawn
raise unless args[:target] == :gold

args = words_db.decompose_command("flibberdygibber whoosafarglebert humperdink")
Log.debug(args)

args = words_db.decompose_command("look self")
Log.debug(args)
raise unless args[:target] == :self

args = words_db.decompose_command("ask self about beef")
Log.debug(args)
raise unless args[:receiver] == :self
raise unless args[:target] == :beef

args = words_db.decompose_command("look at self with microscope")
Log.debug(args)
raise unless args[:command] == :inspect
raise unless args[:target] == :self
raise unless args[:tool] == :microscope
