#!/usr/bin/ruby

require 'words/words'
require 'raws/db'
require 'test/fake'

def recreate_test_character(username, raw_group, clean=true)
    if clean
        userdir = Character.get_user_directory(username)
        Dir.entries(userdir).reject { |file| file == "." || file == ".." }.each { |file| File.delete(File.join(userdir, file)) }
    end

    db = ObjectDB.get(raw_group)
    fake_room = FakeRoom.new
    fake_core = FakeCore.new(db)
    Log.debug("Creating test character using fake state")
    c = db.create(fake_core, :character, {:name => "Test Character", :initial_position => fake_room})
    c.nil_core
    Character.save(username, c)
end
