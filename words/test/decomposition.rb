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

args = Words.decompose_command("aTTack Spider")
raise unless args[:command] == :attack
raise unless args[:target].first == :spider

