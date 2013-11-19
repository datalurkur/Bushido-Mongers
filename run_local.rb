require './bushido'
require './util/traps'
require './util/cfg_reader'
require './net/lobby_bypass_client'

Log.setup("Main", "local")

# FIXME: Used as a stand-in until we have proper game_args being passed into GameCore.
if $TestWorldFactory
    require './test/fake'
    class DefaultCore
        private
        def setup_world(args)
            Log.debug("Creating world")
            @world = $TestWorldFactory.generate(self, args)

            Log.debug("Populating world with NPCs and items")
            @world.populate
        end
    end
end

#MeteredMethods.enable

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
