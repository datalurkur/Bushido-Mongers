require './words/words'
require './raws/db'
require './test/fake'

def recreate_test_character(username, raw_group, clean=true)
    if clean
        userdir = CharacterLoader.get_user_directory(username)
        Dir.entries(userdir).reject { |file| file == "." || file == ".." }.each { |file| File.delete(File.join(userdir, file)) }
    end

    db = ObjectDB.get(raw_group)
    fake_room = FakeRoom.new
    fake_core = FakeCore.new(db)
    Log.debug("Creating test character using fake state")
    c = db.create(fake_core, :character, {:position => fake_room, :name => "Test Character"})
    CharacterLoader.save(username, c)
    c
end

if $0 == __FILE__
    Log.setup("Main", "abilities")
    c = recreate_test_character("test_user", "default")

    Log.debug(c)

    c.instance_exec {
        Log.debug(@attributes)
        Log.debug(@skills)
    }
end
