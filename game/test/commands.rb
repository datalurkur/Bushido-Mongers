require './bushido'
require './test/fake'

Log.setup("Main", "command_test")

$TestWorldFactory = FantasmTestWorldFactory

require './run_local'

$client.stack.specify_response_for(:properties) do |stack, message|
    # NOTE: DEAR GOD DO NOT EVER USE 'puts' FOR ANYTHING
    Log.debug(VerboseInterface.properties(message))
end

$cmd_list = [
    "look",
    "open chest",
    "look in chest",
    "get rock",
    "look self",
    "drop rock"
]

$cmd_index = 0
$waiting_since = 0
$max_wait_time = 3
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
    exec_next_cmd(stack)
end

$client.start
while $client.running?; end

exit($failed)
