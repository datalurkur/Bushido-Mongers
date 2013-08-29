require './bushido'
require './util/traps'
require './util/cfg_reader'
require './net/repro_server'

unless ARGV[0]
    puts "Please specify a repro file"
    exit
end

Log.setup("Main", "repro")

$server = ReproServer.new("test", ARGV[0])

trap_signals do
    $server.stop if $server
    MeteredMethods.report
    exit
end

$server.start

while $server.continue_replay
    sleep 1
end

$server.stop
