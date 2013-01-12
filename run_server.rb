require './util/traps'

# Uncomment to enable code coverage
#require 'util/coverage'
#CodeCoverage.setup

require './util/timer'
#MeteredMethods.enable

require './net/game_server'

Log.setup("Main", "server")

# DEBUG
require './game/test/character'
recreate_test_character("test_user", "default")

trap_signals do
    # TODO - Save the game here so that we don't lose progress
    $server.stop if $server
end

$server = GameServer.new
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
