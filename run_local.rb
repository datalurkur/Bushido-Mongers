require './util/log'
Log.setup("Main", "local")

require './util/timer'
MeteredMethods.enable

require './bushido'
require './util/traps'
require './util/cfg_reader'
require './net/lobby_bypass_client'

config = CFGReader.read("test")
client_config = CFGReader.read("test_lobby").merge(:server_port => config[:listen_port])

$server = GameServer.new("test", Time.now.to_i, "latest.repro")
$client = LobbyBypassClient.new(client_config)

trap_signals do
    # TODO - Save the game here so that we don't lose progress
    $server.stop if $server
    $client.stop if $client
    MeteredMethods.report
    exit
end

$server.start
$client.start

while $client.running?
    sleep 10
end

$server.stop
