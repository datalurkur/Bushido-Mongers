require './messaging/message'
require './words/words'
require './raws/db'
require './test/fake'

Log.setup("Main", "character_test")

fakelobby = FakeLobby.new

core = DefaultCore.new
core.setup(:world_depth => 1, :world_size => 1)

character_details = {
    :name      => "Derpus Maximus",
    :archetype => :giant,
    :morphism  => :male
}

character = core.create_character(fakelobby, "test_user", character_details)
fakelobby.save_core(core, {})
