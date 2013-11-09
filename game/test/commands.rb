require './bushido'
require './test/fake'

Log.setup("Main", "command_test")

$TestWorldFactory = FantasmTestWorldFactory

require './run_local'

$client.stack.specify_response_for(:properties) do |stack, message|
    puts VerboseInterface.properties(message)
end

def cmd_and_wait(stack, cmd)
    stack.put_response(cmd)
    sleep 0.1
end

$client.stack.specify_response_for(:begin_playing) do |stack, message|
    Log.debug("Begin!")
    cmd_and_wait(stack, "look")
    cmd_and_wait(stack, "open chest")
    cmd_and_wait(stack, "look in chest")
    cmd_and_wait(stack, "get rock")
    cmd_and_wait(stack, "look self")
    cmd_and_wait(stack, "drop rock")
    $client.stop
end

# FIXME - doesn't work
$client.stack.specify_response_for(:report) do |stack, message|
    if message.game_event
        Log.debug("Game event!")
        $client.send_to_client(Message.new(:report, {:field => :game_event, :contents => message.details}))
    else
        Log.debug(["Message", message])
    end
end

$client.start
while $client.running?; end
