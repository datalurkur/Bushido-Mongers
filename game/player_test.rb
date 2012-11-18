#!/usr/bin/ruby

require 'game/player'

def recreate_test_player(username, clean=true)
    if clean
        userdir = Player.get_user_directory(username)
        Dir.entries(userdir).reject { |file| file == "." || file == ".." }.each { |file| File.delete(File.join(userdir, file)) }
    end

    p = Player.new("Test Player")
    Player.save_character(username, p)
end
