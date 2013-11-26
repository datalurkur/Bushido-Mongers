require './bushido'
require './util/traps'
require './util/cfg_reader'
require './net/lobby_bypass_client'
require './test/fake'

Log.setup("Main", "command_test")

# FIXME: Used as a stand-in until we have proper game_args being passed into GameCore.
class DefaultCore
    private
    def setup_world(args)
        Log.debug("Creating world")
        @world = FantasmTestWorldFactory.generate(self, args)

        Log.debug("Populating world with NPCs and items")
        @world.populate
    end
end

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

$client.stack.specify_response_for(:properties) do |stack, message|
    Log.debug(VerboseInterface.properties(message))
end

$cmd_list = [
    "look",
    "open chest",
    "look in chest",
    "get rock",
    "look self",
    "drop rock",
    "/spawn fiber",
    "get fiber",
    "craft thread",
    "craft fabric"
]

$cmd_index = 0
$waiting_since = 0
$max_wait_time = 5
$mutex = Mutex.new
$failed = false

def exec_next_cmd(stack)
    $mutex.synchronize {
        $waiting = Time.now.to_i
    }
    if $cmd_index >= $cmd_list.size
        Log.info("All commands executed successfully, attempting to exit via command")
        stack.put_response("/quit")
    else
        next_cmd = $cmd_list[$cmd_index]
        $cmd_index += 1
        Log.info("Executing #{next_cmd}")
        stack.put_response(next_cmd)
    end
end

def start_watchdog_thread
    Thread.new do
        sleep $max_wait_time
        $mutex.synchronize {
            $failed = true if Time.now.to_i - $waiting_since > $max_wait_time
        }
        if $failed
            Log.error("Failed to get a command response, exiting")
            $client.stop
        end
    end
end

$client.stack.specify_response_for(:begin_playing) do |stack, message|
    exec_next_cmd(stack)
    start_watchdog_thread
end

$client.stack.specify_response_for(:report, :field => :action_results) do |stack, message|
    Log.info("Action results: #{message.contents}")
    exec_next_cmd(stack)
end

$client.stack.specify_response_for(:report, :field => :game_event) do |stack, message|
    Log.info("Game event: #{message.contents}")
end

$server.start
$client.start

while $client.running?
    sleep 1
end

$server.stop

exit($failed)
