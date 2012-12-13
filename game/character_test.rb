#!/usr/bin/ruby

require 'game/character'
require 'vocabulary'

def recreate_test_character(username, clean=true)
    if clean
        userdir = Character.get_user_directory(username)
        Dir.entries(userdir).reject { |file| file == "." || file == ".." }.each { |file| File.delete(File.join(userdir, file)) }
    end

    c = Character.new(Words.find(:keyword => :japanese, :wordtype => :name).map(&:to_s).rand)

    Character.save(username, c)
end
