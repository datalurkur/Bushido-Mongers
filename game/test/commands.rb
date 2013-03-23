require './bushido'
require './test/fake'

Log.setup("Main", "command_test")

def fantasmagoria(core, args={})
    # a---b

    a = Room.new(core, "West Fantasm", Zone.get_params(core, nil, 0))
    a.connect_to(:east)

    b = Room.new(core, "East Fantasm", Zone.get_params(core, nil, 0))
    b.connect_to(:west)

    world = World.new(core, "Fantasmagoria", 2, 1)
    world.set_zone(0,0,a)
    world.set_zone(1,0,b)

    world.add_starting_location(a)
    world.check_consistency
    world.finalize
    world
end

# Tee-hee!
class GameCore
    private
    def setup_world(args)
        Log.debug("Creating Fantasmagoria")
        @world = fantasmagoria(self, args)

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
end

$client.start
sleep 2
