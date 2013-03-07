require './words/words'
require './raws/db'
require './test/fake'

def recreate_test_character(username, character_name, raw_group, clean=true)
    if clean
        userdir = CharacterLoader.get_user_directory(username)
        Dir.entries(userdir).reject { |file| file == "." || file == ".." }.each { |file| File.delete(File.join(userdir, file)) }
    end

    Log.debug("Creating test character using fake state")
    fake_core = FakeCore.new(ObjectDB.get(raw_group))
    character = fake_core.create(:character, {:name => character_name})
    CharacterLoader.save(username, character)
    character
end

def reload_test_character(username, character_name, raw_group)
    Log.debug("Reloading test character")
    fake_core = FakeCore.new(ObjectDB.get(raw_group))
    character = CharacterLoader.attempt_to_load(fake_core, username, character_name)
end

username = "test_user"
character_name = "Test Character"
raw_group = "default"

Log.setup("Main", "abilities")
c = recreate_test_character(username, character_name, raw_group)

Log.debug(c)

c.instance_exec {
    Log.debug(@attributes)
    Log.debug(@skills)
}

d = reload_test_character(username, character_name, raw_group)
