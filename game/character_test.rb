#!/usr/bin/ruby

require 'game/character'
require 'words/words'

def recreate_test_character(username, clean=true)
    if clean
        userdir = Character.get_user_directory(username)
        Dir.entries(userdir).reject { |file| file == "." || file == ".." }.each { |file| File.delete(File.join(userdir, file)) }
    end

    c = Character.new(username)

    Character.save(username, c)
end
