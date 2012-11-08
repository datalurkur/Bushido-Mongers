#!/usr/bin/ruby

require 'game_server'

config = {
    :irc_enabled => false,
    :irc_server  => "irc.freenode.net",
    :irc_port    => 7000,
    :irc_nick    => "ninja_game_bot",
    :listen_port => 9999,
}

Log.setup
s = GameServer.new(config)

while s.is_running?
end

s.teardown
