#!/usr/bin/ruby

require 'net/game_server'

config = {
    :irc_enabled => false,
    :irc_server  => "irc.freenode.net",
    :irc_port    => 7000,
    :irc_nick    => "ninja_game_bot",
    :listen_port => 9999,
    :motd        => "Youkoso!",
}

Log.setup("Main Thread", "server")

# DEBUG
require 'game/player_test'
recreate_test_player("test_user")

s = GameServer.new(config)

while s.is_running?
end

s.teardown
