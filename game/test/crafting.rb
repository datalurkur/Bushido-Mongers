require './test/fake'

Log.setup("Main", "abilities")

core = CoreWrapper.new

test_room = Room.new(core, "Test Room")

test_objects = [:sword_blade, :long_handle]
test_components = []
test_objects.each do |object_type|
    test_components << core.create(object_type, {:randomize => true, :position => test_room})
end

test_character = core.create_agent(:human, true, {:name => "Test Character", :position => test_room})

# TODO - Add a test for actual phrase decomp here, once that code is done

command = :craft
command_arguments = {
    :agent      => test_character,
    :target     => :katana,
    :components => [:blade]
}

test_components.each do |component|
    test_character.stash(component)
end
Commands.stage(core, command, command_arguments)
Commands.do(core, command, command_arguments)
