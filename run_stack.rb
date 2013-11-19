require './bushido'
require './util/traps'
require './util/cfg_reader'
require './net/lobby_bypass_client'

Log.setup("Main", "stack")

config = CFGReader.read("test")
client_config = CFGReader.read("test_lobby").merge(:server_port => config[:listen_port])

$client = LobbyBypassClient.new(client_config)

trap_signals do
    $client.stop if $client
    exit
end

$client.start

while $client.running?
    sleep 10
end
