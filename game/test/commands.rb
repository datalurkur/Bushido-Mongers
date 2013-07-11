require './bushido'
require './test/fake'

Log.setup("Main", "command_test")

# FIXME: Used as a stand-in until we have proper game_args being passed into GameCore.
class DefaultCore
    private
    def setup_world(args)
        Log.debug("Creating world")
        @world = ZoneLineWorldFactory.generate(self, args)

        Log.debug("Populating world with NPCs and items")
        @world.populate
    end
end

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
    $client.release_control
    $client.stop
end

$client.start
while $client.running?; end
