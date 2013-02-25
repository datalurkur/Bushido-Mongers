require './bushido'
require './util/traps'

Log.setup("Main", "server")

trap_signals do
    # TODO - Save the game here so that we don't lose progress
    $server.stop if $server
end

$server = GameServer.new("net")
$server.start
while $server.is_running?
    sleep 10
end
