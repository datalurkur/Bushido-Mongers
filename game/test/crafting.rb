# FIXME - Test recipes with missing components.
# FIXME - Verify technique/skill is used and improved.
# FIXME - Make errors when location isn't respected - e.g. forging while not at an anvil.

require './test/fake'

Log.setup("Main", "abilities")

core = FakeCore.new

def all_recipes(core)
	core.db.instantiable_types_of(:made).inject([]) do |arr, made|
		core.db.info_for(made, :recipes).each { |recipe| arr << [made, recipe] }
		arr
	end
end

def random_recipe(core)
	all_recipes(core).rand
end

def stash_components_for_recipe(core, stasher, components)
	Array(components).each do |object_type|
		component = core.create(object_type, {:randomize => true, :position => stasher.absolute_position})
		if !stasher.available_grasper
			Log.debug("Creating extra arm for #{component.get_type}")
			core.create(:arm, {:position => stasher, :position_type => :external})
		end
		stasher.stash(component)
	end
	Log.debug(core.words_db.describe_inventory(stasher))
end

def make_random_recipe(core)
	target_type, recipe = random_recipe(core)
	make_recipe(core, target_type, recipe)
end

def make_recipe(core, target_type, recipe)
	Log.debug([target_type, recipe])

	test_room      = core.create(FakeRoom)
	test_character = core.create_npc(:human, {:name => "Test Character", :position => test_room})

	stash_components_for_recipe(core, test_character, recipe[:components])

	# TODO - Using recipe[:technique] here instead of the generic :craft
	# requires a skill=>command mapping, which doesn't exist yet.
	params = recipe.merge(:command => :craft, :agent => test_character, :target => target_type)

	Commands.stage(core, params)
	Commands.do(core, params)

	Log.debug(core.words_db.describe_inventory(test_character))
end

def craft(core, command, components = [])
	test_room = core.create(FakeRoom)
	test_character = core.create_npc(:human, {:name => "Test Character", :position => test_room})
	stash_components_for_recipe(core, test_character, components)

	params = core.words_db.decompose_command(command)
	params = params.merge(:agent => test_character)

	Commands.stage(core, params)
	Commands.do(core, params)

	Log.debug(core.words_db.describe_inventory(test_character))
end

=begin
make_recipe(core, :handle, { :components => [ :leather ], :technique  => :craft })
make_recipe(core, :fabric, { :components => [ :thread ],  :technique  => :weave })
make_recipe(core, :matchlock, { :components => [ :metal, :metal, :metal, :wood, :wood ], :technique  => :forge })

10.times {
	make_random_recipe(core)
}
=end

all_recipes(core).each do |target_type, recipe|
	make_recipe(core, target_type, recipe)
end

katana_specs = {
	"craft katana" => {:components => [:long_handle, :sword_blade]},
	# TODO - fix "You don't have enough long_handle."
	"craft katana" => {:error => FailedCommandError, :components => [:sword_blade]},
	# TODO - Can't specify partial components yet.
	"craft katana from sword_blade" => {:error => FailedCommandError, :components => [:sword_blade]},
	# FIXME - Decomposition doesn't handle multiple components properly yet.
	#craft(core, "craft katana from sword_blade and long_handle")
}
katana_specs.each do |command, info|
	begin
		craft(core, command, info[:components])
	rescue Exception => e
		if info[:error] && e.is_a?(info[:error])
			Log.debug("#{info[:error]} intercepted")
		else
			raise "Unexpected error #{e.inspect} #{e.backtrace} for #{command}: #{info.inspect}"
		end
	end
end
