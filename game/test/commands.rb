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

$client.stack.specify_response_for(:begin_playing) do |stack, message|
    Log.debug("Begin!")
    stack.put_response("look")
    stack.put_response("open chest")
    stack.put_response("look in chest")
end

$client.start

start_time = Time.new
while $client.running? && !(Time.new > start_time + 3)
    sleep 10
end
