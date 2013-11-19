require './util/log'

module Commands
    class << self
        def get_command_module(core, command)
            unless core.db.static_types_of(:command).include?(command)
                raise(InvalidCommandError, "Command #{command.to_s.inspect} not found.")
            end

            invocation = core.db.info_for(command, :invocation) || command
            invocation.to_caml.to_const(Commands)
        end

        def stage(core, command, params)
            raise(ArgumentError, "An agent must be present for a command to be staged") unless params[:agent]
            mod = get_command_module(core, command)
            params.merge!(:command => command)
            mod.stage(core, params)
            params
        end

        def do(core, command, params)
            mod = get_command_module(core, command)
            mod.do(core, params) if mod.respond_to?(:do)
        end

        # Requires standard param values: agent, command, and the given key.
        def find_object_for_key(core, params, key, object_type = nil, search_locations = [:all], optional = [])
            search_locations = Array(search_locations)
            optional         = Array(optional)
            if params[key].nil?
                Log.warning("Finding object for nil parameter #{key.inspect}")
                return
            end

            object_type ||= params[key] if core.db.has_type?(params[key])
            object_type ||= core.db.info_for(params[:command], key)

            Log.debug(object_type)
            result = params[:agent].find_object(
                            object_type,
                            params[key],
                            params[(key.to_s + "_adjs").to_sym] || [],
                            search_locations
                          )
            Log.debug("Found #{result.monicker} for #{key}", 6)
            result
        end

        def find_and_set_object_for_key(core, params, key, object_type = nil, search_locations = [:all], optional = [])
            params[key] = find_object_for_key(core, params, key, object_type, search_locations, optional)

            verify_params(params, [key], optional)
        end

        def verify_params(params, required, optional = [])
            missing_params = required.select { |k| params[k].nil? }
            raise AmbiguousCommandError.new(params[:command], missing_params) unless missing_params.empty?
            unused_params = params.keys - (required + optional) - [:agent, :command, :verb]
            unused_params.each do |key|
                Log.debug("Parameter #{key.inspect} found but not required or optional. Add searching for this parameter to #{params[:command]}")
            end
        end


        def find_all_objects(agent, object_type, object_string, locations)
            Log.debug("Finding all objects" +
                      (object_string ? " named #{object_string.inspect}" : '') +
                      (object_type   ? " of type #{object_type.inspect}" : '') +
                      (locations     ? " in #{locations.inspect}"        : '') +
                      " for #{agent.monicker}")
            agent.find_all_objects(object_type, object_string, locations)
        end

        metered :find_all_objects, :verify_params, :find_and_set_object_for_key, :find_object_for_key, :do, :stage
    end

    ### HELPER COMMANDS ###
    # TODO - Consider removing these in favor of their corresponding commands

    module Stats
        def self.stage(core, params)
            unless params[:agent].uses?(HasAspects)
                raise(InvalidCommandError, "No aspects!")
            end
            # Reach into agent and pull out stat details.
            params[:list] = params[:agent].all_aspects
        end
    end

    module Help
        def self.stage(core, params)
            params[:list] = core.db.static_types_of(:command)
        end
    end

    module Inventory
        def self.stage(core, params)
            raise(MissingObjectExtensionError, "Must have an inventory!") unless params[:agent].uses?(Equipment)
            [:grasped, :worn].each do |location|
                params[location] = params[:agent].objects_in_location(location)
            end
        end
    end

    ### WORLD-INTERACTION COMMANDS ###

    module Look
        def self.stage(core, params)
            if params[:location]
                Commands.find_and_set_object_for_key(core, params, :location)

                if params[:location].is_type?(:container) && !params[:location].open?
                    raise(FailedCommandError, "#{params[:location].monicker} is closed.")
                end
            end

            target = params[:target]
            if target
                # Examine the agent in the event of :self, :me, etc.
                if (core.words_db.associated_words_of(:self, :synonym)+[:self]).include?(target)
                    params[:target] = params[:agent]
                else
                    Commands.find_and_set_object_for_key(core, params, :target)
                end
            else
                # Assume the player wants a broad overview of what he can see, describe the room
                params[:target] = params[:agent].absolute_position
            end
        end
    end

    module Inspect
        def self.stage(core, params) Look.stage(core, params); end
    end

    module Consume
        def self.stage(core, params)
            target_class = params[:agent].class_info[:consumes]
            Commands.find_and_set_object_for_key(core, params, :target, target_class, [:inventory, :position])

            unless params[:agent].class_info[:on_consume] || params[:target].is_type?(:consumable)
                raise(FailedCommandError, "#{params[:agent].monicker} doesn't know how to eat a(n) #{params[:target].monicker}")
            end
        end

        def self.do(core, params)
            agent = params[:agent]
            # Special consumption.
            if agent.class_info[:consumes]
                Log.info("#{agent.monicker} eats a #{params[:target].monicker}!")
            elsif params[:target].is_type?(:consumable)
                # Do normal consumption
                Log.info("#{agent.monicker} eats #{params[:target].monicker} like a normal person.")
            end
            # TODO - Determine what organ to use for digestion based on the raws, rather than assuming the eater has a stomach
            digesters = params[:agent].find_body_parts(:stomach)
            if digesters.empty?
                Log.error("#{params[:agent].monicker} has no organs that can digest things!")
                return
            else
                params[:target].set_position(digesters.rand, :internal)
            end
        end
    end

    module Get
        def self.stage(core, params)
            raise(MissingObjectExtensionError, "Must have an inventory to pick things up!") unless params[:agent].uses?(Equipment)
            Commands.find_and_set_object_for_key(core, params, :target, nil, [:position, :stashed, :worn])
        end

        def self.do(core, params)
            params[:agent].stash(params[:target])
        end
    end

    module Stash
        def self.stage(core, params)
            raise(MissingObjectExtensionError, "Must have an inventory to pick things up!") unless params[:agent].uses?(Equipment)
            Commands.find_and_set_object_for_key(core, params, :target, nil, [:position, :stashed, :worn])
        end

        def self.do(core, params)
            params[:agent].stash(params[:target])
        end
    end

    module Drop
        def self.stage(core, params)
            raise(MissingObjectExtensionError, "Must have an inventory to pick things up!") unless params[:agent].uses?(Equipment)
            Commands.find_and_set_object_for_key(core, params, :target, nil, [:inventory])
        end

        def self.do(core, params)
            params[:target].set_position(params[:agent].absolute_position, :internal)
        end
    end

    module Equip
        def self.stage(core, params)
            Commands.find_and_set_object_for_key(core, params, :target, nil, [:grasped, :stashed])
            # TODO - take 'on' preposition that establishes destination
            #Commands.find_and_set_object_for_key(core, params, :destination, nil, [:external])
        end

        def self.do(core, params)
            agent     = params[:agent]
            equipment = params[:target]
            equipment_types = equipment.type_ancestry

            Log.debug("#{agent.monicker} trying to equip #{equipment.monicker} #{equipment_types.inspect}")
            if agent.uses?(Equipment)
                parts_can_equip = agent.external_body_parts.select do |part|
                    ((part.properties[:can_equip] || []) & equipment_types).size > 0
                end

                if parts_can_equip.empty?
                    raise(FailedCommandError, "#{agent.monicker} can't wear #{equipment.monicker}!")
                end

                # Look for parts that can equip the item that are also free.
                parts_can_wear = parts_can_equip.select { |part| !part.full?(:worn) }

                # wear() will throw the equippable-but-not-free slot exception for us.
                part_to_equip = parts_can_wear.first || parts_can_equip.first
                agent.wear(part_to_equip, equipment)
                params[:destination] = part_to_equip
            else
                raise(FailedCommandError, "#{agent.monicker} can't wear anything!")
            end
        end
    end

    module Unequip
        def self.stage(core, params)
            Commands.find_and_set_object_for_key(core, params, :target, nil, [:worn])
            # TODO - take 'on' preposition that establishes destination
            #Commands.find_and_set_object_for_key(core, params, :destination, nil, [:external])
        end

        def self.do(core, params)
            agent     = params[:agent]
            equipment = params[:target]

            Log.debug("Looking to unequip #{equipment.monicker}")
            if agent.uses?(Equipment)
                agent.remove(equipment)
            else
                raise(FailedCommandError, "#{agent.monicker} doesn't know how to remove #{equipment.monicker}!")
            end
        end
    end

    module Move
        def self.stage(core, params)
            raise AmbiguousCommandError.new(params[:command], [:destination]) unless params[:destination]
            destination = params[:destination]

            position = params[:agent].absolute_position
            raise(NotImplementedError, "You're trapped in a #{position.monicker}!") unless Room === position

            # This method raises an exception if the direction is invalid, so no need to check it
            params[:destination] = position.get_adjacent(destination)
            params[:direction] = destination
        end

        def self.do(core, params)
            params[:agent].set_position(params[:destination], :internal, true)
        end
    end

    module Hide
        def self.stage(core, params)
            if params[:agent].get_aspect(:stealth).properties[:hidden]
                raise(FailedCommandError, "You are already hidden.")
            end
        end

        def self.do(core, params)
            params[:agent].get_aspect(:stealth).properties[:hidden] = true
        end
    end

    module Unhide
        def self.stage(core, params)
            if !params[:agent].get_aspect(:stealth).properties[:hidden]
                raise(FailedCommandError, "You are not in hiding.")
            end
        end

        def self.do(core, params)
            params[:agent].get_aspect(:stealth).properties[:hidden] = false
        end
    end

    module Attack
        def self.stage(core, params)
            if params[:tool]
                Commands.find_and_set_object_for_key(core, params, :tool, nil, [:grasped])
            end

            Commands.find_and_set_object_for_key(core, params, :target)
            # Search within the target for the location, if it exists.
            if params[:location]
                Commands.find_and_set_object_for_key(core, params, :location, nil, [params[:target]])
            end
        end

        def self.do(core, params)
            attacker = params[:agent]
            defender = params[:target]

            unless attacker.uses?(HasAspects)
                raise(FailedCommandError, "#{attacker.monicker} is attacking #{defender.monicker} without aspects!")
            end

            skill = :intrinsic_fighting
            result_hash = {}
            damage = 5

            if params[:tool]
                weapon = params[:tool]
            elsif attacker.uses?(Equipment) && attacker.has_weapon?
                weapon = attacker.weapon
            end

            if weapon
                if weapon_skill = core.db.info_for(weapon.get_type, :skill_used)
                    skill = weapon_skill
                end

                if damage_type = core.db.info_for(weapon.get_type, :type)
                    result_hash[:damage_type] = damage_type
                end

                result_hash[:tool] = weapon
            end

            check_results = attacker.make_opposed_attempt(skill, defender)
            success = check_results[0]

            # Target the body if location not specified
            target = params[:location] || defender
            result_hash[:subtarget] = params[:location]

            print = params[:location] ? "in the #{params[:location].monicker}" : ''
            Log.debug("#{attacker.monicker} attacks #{defender.monicker} #{print}")

            if success
                result_hash[:damage] = damage
                target.damage(damage, attacker)
            end

            # TODO - Add the results of opposed checks to the message
            locations = [attacker.absolute_position, defender.absolute_position]
            Message.dispatch_positional(core, locations, :unit_attacks, {
                :attacker      => attacker,
                :defender      => defender,
                :success       => success,
                :result_hash   => result_hash
            })
            core.destroy_flagged
        end
    end

    module Open
        def self.stage(core, params)
            Commands.find_and_set_object_for_key(core, params, :target, nil, [:position, :inventory])

            if params[:target].open?
                raise(FailedCommandError, "#{params[:target].monicker} is already open.")
            elsif !params[:target].is_type?(:container)
                raise(FailedCommandError, "#{params[:target].monicker} cannot be opened.")
            end
        end

        def self.do(core, params)
            params[:target].properties[:open] = true
        end
    end

    module Close
        def self.stage(core, params)
            Commands.find_and_set_object_for_key(core, params, :target, nil, [:position, :inventory])

            if !params[:target].open?
                raise(FailedCommandError, "#{params[:target].monicker} is already closed.")
            elsif !params[:target].is_type?(:container)
                raise(FailedCommandError, "#{params[:target].monicker} cannot be opened.")
            end
        end

        def self.do(core, params)
            params[:target].properties[:open] = false
        end
    end

    ### NPC-PC INTERACTION COMMANDS ###

    module Say
        def self.stage(core, params)
            if params[:receiver]
                Commands.find_and_set_object_for_key(core, params, :receiver, nil, [:position], [:statement])
            end
        end

        def self.do(core, params)
            params[:agent].say(params[:receiver], params[:statement], true)
        end
    end

    module Whisper
        def self.stage(core, params)
            # Look for receiver. We should probably set it to :self or something otherwise.
            Commands.find_and_set_object_for_key(core, params, :receiver, nil, [:position], [:statement])
        end

        def self.do(core, params)
            params[:agent].whisper(params[:receiver], params[:statement], true)
        end
    end

    module Ask
        def self.stage(core, params)
            Commands.find_and_set_object_for_key(core, params, :receiver, nil, [:position])
        end

        def self.do(core, params)
            message = Message.new(:unit_speaks, {
                :agent           => params[:agent],
                :receiver        => params[:receiver],
                :statement       => params[:statement],
                :response_needed => true
            })
            if params[:receiver]
                params[:receiver].process_message(message)
            else
                Log.warning("Ask with no receiver?")
                message.params[:receiver] = :nobody
                locations = [params[:agent].absolute_position]
                Message.dispatch_positional(core, locations, message.type, message.params.merge(:statement => ''))
            end
        end
    end

    module Make
        def self.stage(core, params)
=begin
            Here we need to take some combination of:
                - a target object (to be :made)
                - a list of components
                - a technique
                - a tool
                - a location
            and
                a) Return more information about that thing (or query for more information about the intention)
                b) Link those things into a recipe and prepare to construct it
=end
            raise(MissingObjectExtension, "Only creatures with skill can make objects") unless params[:agent].uses?(HasAspects)
            Log.debug("#{params[:agent].monicker} is attempting to #{params[:command]} an object")

            raise(MissingProperty, "What do you want to #{params[:command]}?") unless params[:target]

            # If the player has a goal of what they want to make in mind, find the recipes for that thing and then see if the rest of the information given by the player is enough to establish which recipe they want to use
            Log.debug("Target provided - #{params[:target].inspect}")
            # Verify that the target is :made
            raise(NoMatchError, "#{params[:target]} cannot be made.") unless core.db.is_type?(params[:target], :made)

            # Find a recipe (or throw an exception if there's a problem)
            params[:recipe] = find_recipe(core, params)
            #params[:recipe] = get_recipe(core, params)

            # Now we have to check that the player actually has access to all of the stuff in the params
            # TODO - find_object functionality can deal with abstract object types like :metal
            Commands.find_and_set_object_for_key(core, params, :location, nil, [:position], [:tool])
            Commands.find_and_set_object_for_key(core, params, :tool,     nil, [:inventory])

            # We have enough information to construct something!
        end

        def self.do(core, params)
            # Determine object quality
            related_skill        = core.db.info_for(params[:command])[:skill] || params[:command]
            # FIXME - Add difficulties based on materials and recipes (a recipe might be easy to make with copper, but much harder with steel, for example)
            crafting_difficulty  = Difficulty.standard
            skill_roll           = params[:agent].make_attempt(related_skill, crafting_difficulty)
            quality_value        = Quality.value_of(Quality.standard) + skill_roll

            if (0..1).include?(quality_value)
                quality = Quality.value_at(quality_value)

                # Construct the new object
                # The "made" extension ensures that components are removed from the world, quality is computed correctly given the quality of the ingredients, and the creator is assigned
                core.create(params[:target], {
                    :components => params[:components],
                    :quality    => quality,
                    :creator    => params[:agent]
                })
                Log.debug("#{params[:agent].monicker} has #{params[:command]}ed a #{quality} #{params[:target]}")
            else
                # Failed!  Destroy the components
                params[:components].each do |component|
                    component.destroy(params[:agent])
                end
                Log.debug("#{params[:agent].monicker} flubbed an attempt to #{params[:command]} a #{params[:target]}")
            end
        end

        def self.contains_type?(core, type, list)
            match = nil
            list.each do |item|
                Log.debug("Is #{item.monicker} a #{type.inspect}?")
                if core.db.is_type?(item.get_type, type)
                    match = item
                    break
                end
            end
            match
        end

        def self.compare_and_find_object(core, params, recipes, param, search_locations)
            if params[param]
                recipes = recipes.select { |r| r[param] == params[param] }
                if recipes.empty?
                    raise(FailedCommandError, "No recipes found for #{param} #{params[param]}")
                end
            else
                # Search for the parameter.
                recipes.each do |recipe|
                    if recipe[param]
                        Log.debug("Recipe has #{param} #{recipe[param]}", 9)
                    else
                        Log.debug("Searching for object for #{param}")
                        Commands.find_and_set_object_for_key(core, params, param, search_locations[param])
                    end
                end
            end
        end

        # TODO: Send the failure messages back to be formatted by Words.
        def self.get_recipe(core, params)
            # Get all recipes for the intended object and do a little massaging.
            recipes = core.db.info_for(params[:target], :recipes)

            search_locations =
            {
                :location => [:position],
                :tool     => [:grasped, :stashed]
            }

            [:location, :tool].each do |param|
                compare_and_find_object(core, params, recipes, param, search_locations[param])
            end

            # Find objects matching any given components
            found_objects = []
            (param[:components] || []).each do |component|
            end

        end

        def self.find_recipe(core, params)
            # Get a list of recipes used to make the thing
            # TODO - Use player knowledge of recipes here
            recipes = core.db.info_for(params[:target], :recipes)
            Log.debug(["#{recipes.size} recipes found for #{params[:target].inspect} - ", recipes])
            failure_string = "You don't know how to #{params[:command]} a #{params[:target]}"
            raise(FailedCommandError, "#{failure_string}.") if recipes.empty?

            # Begin filtering the recipes based on parametes

            # Find recipes that use the "technique" given by the command
            recipes = recipes.select { |r| r[:technique] == params[:command] }
            raise(FailedCommandError, "#{failure_string}, perhaps try a different technique.") if recipes.empty?

            # Find recipes that use the location given (anvil, for example)
            if params[:location]
                failure_string += " at a #{params[:location]}"
                recipes = recipes.select { |r| r[:location] == params[:location] }
                raise(FailedCommandError, "#{failure_string}, perhaps try a different location.") if recipes.empty?
            end

            # Find recipes that use the tool given (hammer, for example)
            if params[:tool]
                failure_string += " with a #{params[:tool]}"
                recipes = recipes.select { |r| r[:tool] == params[:tool] }
                raise(FailedCommandError, "#{failure_string}, perhaps try a different tool.") if recipes.empty?
            end

            # Construct a hash that will store a mapping of real-world components to component requirements
            recipe_map    = {}
            recipes.each do |recipe|
                recipe_map[recipe] = {
                    :requirements => recipe[:components].dup,
                    :components   => []
                }
            end

            # Begin mapping the given components onto the recipe requirements
            component_map = {}
            if params[:components]
                # For each component provided, get a list of world objects that match
                Log.debug("Resolving recipe components")
                Array(params[:components]).each do |component|
                    # Find all the stuff that matches this and get the corresponding types
                    component_map[component] = Commands.find_all_objects(params[:agent], nil, component, [:inventory])
                    raise(NoMatchError, "Unable to find '#{component}'") if component_map[component].empty?
                    Log.debug("Component #{component} matched to #{component_map[component].size} objects")
                end

                # Iterate through the recipes, attempting to match up components with requirements
                Log.debug("Mapping recipe components")
                rejected_recipes = []
                recipe_map.each do |recipe,recipe_data|
                    Log.debug(["Mapping components for", recipe])
                    full_match = true
                    # Loop over user-provided components first, so that extra components can be caught early
                    component_map.each do |component,component_matches|
                        Log.debug("Finding requirement matches for #{component.inspect}")
                        # Every component in the map must have a valid match, or this recipe is not valid
                        match = nil
                        recipe_data[:requirements].each do |requirement|
                            Log.debug("Checking #{requirement.inspect} for a match")
                            if (match = contains_type?(core, requirement, component_matches))
                                Log.debug("Recipe requirement #{requirement} matches an entry for #{component} (#{match.monicker})")
                                recipe_data[:components] << match
                                recipe_data[:requirements].delete(requirement)
                                break
                            end
                        end
                        unless match
                            Log.debug("Component #{component} was not matched to a recipe requirement")
                            full_match = false
                            break
                        end
                    end
                    unless full_match
                        Log.debug("Recipe #{recipe} has a match with user-specified components")
                        rejected_recipes << recipe
                    end
                end
                rejected_recipes.each { |r| recipe_map.delete(r) }
            end

            # Fill in missing components for recipes
            rejected_recipes  = []
            ambiguous_recipes = []
            recipe_map.each do |recipe,recipe_data|
                Log.debug(["Filling in missing requirements for", recipe])
                recipe_data[:requirements].each do |requirement|
                    matches = Commands.find_all_objects(params[:agent], requirement, nil, [:inventory])
                    matches.reject! { |o| recipe_data[:components].include?(o) }
                    if matches.size > 1
                        Log.debug(["Multiple matches found for recipe requirement #{requirement}", matches])
                        ambiguous_recipes << recipe
                        break
                    elsif matches.empty?
                        Log.debug("No matches found for recipe requirement #{requirement}")
                        rejected_recipes << recipe
                        break
                    else
                        recipe_data[:components] << matches[0]
                    end
                end
            end

            rejected_recipes.each { |r| recipe_map.delete(r) }
            raise(NoMatchError, "Unable to gather the materials needed to #{params[:command]} a #{params[:target]}") if recipe_map.empty?
            ambiguous_recipes.each { |r| recipe_map.delete(r) }
            raise(NoMatchError, "It is unclear what available materials should be used to #{params[:command]} a #{params[:target]}") if recipe_map.empty?
            raise(NoMatchError, "It is unclear what available materials should be used to #{params[:command]} a #{params[:target]}: options are: #{recipe_map.inspect}") if  recipe_map.size > 1
            recipe = recipe_map.keys[0]

            # If we had enough parameters to select a recipe, but some were left blank, fill in the missing pieces in the parameters before object lookup
            Log.debug("Clarifying tool and location if necessary")
            [:tool, :location].each do |key|
                params[key] ||= recipe[key] if recipe[key]
            end

            Log.debug("Re-mapping components")
            params[:components] = recipe_map[recipe][:components]

            Log.debug("Done!")
            return recipe
        end
    end
end
