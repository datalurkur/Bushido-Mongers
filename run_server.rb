#!/usr/bin/ruby

# Uncomment to enable code coverage
#require 'util/coverage'
#CodeCoverage.setup

require 'util/timer'
MeteredMethods.enable

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
require 'game/character_test'
recreate_test_character("test_user")

signals = ["TERM","INT"]
signals.each do |signal|
    Signal.trap(signal) {
        # TODO - Save the game here so that we don't lose progress
        Log.debug("Caught signal #{signal}")
        $server.stop if $server
    }
end

$server = GameServer.new(config)
$server.start
while $server.is_running?
end

MeteredMethods.report

# Uncomment to enable code coverage output
# (be sure to also uncomment the code coverage lines at the top of this file)
=begin
puts "CodeCoverage Results:"
CodeCoverage.results.each do |klass, hash|
    puts "\t#{klass}"
    sorted_keys = hash.keys.sort { |x,y| x.to_s <=> y.to_s }
    sorted_keys.each do |file|
        calls = hash[file]
        puts "\t\t#{calls} : #{file}"
    end
end
=end
