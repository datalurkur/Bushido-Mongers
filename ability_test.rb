require 'game/ability'
require 'raws/db'

Log.setup("Main", "ability_test")

db = ObjectDB.new("default")
Log.debug(["Abilities:", db.types_of(:ability)])
hide_ability = db.create(:hide)
hide_ability.attempt(:hard)
