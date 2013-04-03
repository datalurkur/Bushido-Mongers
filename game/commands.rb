require './util/log'

module Commands
    class << self
        def get_command_module(core, command)
            unless core.db.types_of(:command).include?(command)
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

        # Requires standard param values: agent, command.
        # Requires parameter 'filters', which is a hash:
        #  key: parameter to lookup.
        #  value: where to look for the object, in order.
        # Takes optional parameter value :'key'_type_class, where 'key' is a key of :needed.
        def find_objects(core, params, filters, optional=[])
            missing_params = []
            filters.keys.each do |req|
                missing_params << req unless params[req] || optional.include?(req)
            end
            unless missing_params.empty?
                clarify_string = "#{params[:command].title}"
                missing_params.each do |missing|
                    case missing
                    when :target
                        clarify_string += " what"
                    when :tool
                        clarify_string += " with what"
                    when :location
                        clarify_string += " where"
                    else
                        Log.error("Can't format parameter #{missing}")
                    end
                end
                clarify_string += "?"
                raise(AmbiguousCommandError, clarify_string)
            end

            filters.each do |p, lookup_locs|
                params[p] = params[:agent].find_object(
                    params[:"#{p}_type_class"] || core.db.info_for(params[:command], p),
                    params[p],
                    params[(p.to_s + "_adjs").to_sym] || [],
                    lookup_locs
                )
                Log.debug("Found #{params[p].monicker} for #{p}")
            end

            unless params[:no_sanity_check]
                params.keys.select { |p| params[p].is_a?(Array) }.each do |p|
                    Log.debug("Parameter #{p.inspect} found from text but not searched for! Add searching for this parameter to #{params[:command]}.")
                    # FIXME - there might be valid reasons to return an array... Handle this in a more robust way.
                    params.delete(p)
                end
            end
        end

        def find_all_objects(agent, object_type, object_string, locations)
            Log.debug("Finding all objects named #{object_string.inspect} of type #{object_type.inspect} for #{agent.monicker} in #{locations.inspect}")
            agent.find_all_objects(object_type, object_string, locations)
        end
    end

    ### HELPER COMMANDS ###
    # TODO - Consider removing these in favor of their corresponding commands

    module Stats
        def self.stage(core, params)
            unless params[:agent].uses?(HasAspects)
                raise(InvalidCommandError, "No aspects!")
            end
            # Reach into agent and pull out stat details.
            list = []
            list << params[:agent].attributes.values
            list << params[:agent].skills.values
            params[:target] = list
        end
    end

    module Help
        def self.stage(core, params)
            params[:target] = core.db.types_of(:command)
        end
    end

    ### WORLD-INTERACTION COMMANDS ###

    module Inspect
        def self.stage(core, params)
            if params[:location]
                Commands.find_objects(core, params, :location => [:grasped, :worn, :stashed, :position])
                if params[:location].container? && !params[:location].open?
                    raise(FailedCommandError, "#{params[:location].monicker} is closed.")
                end
            end

            target = params[:target]
            if !target.nil? && (params[:agent].monicker.match(target.to_s) || (Words.db.get_related_words(:self)+[:self]).include?(target))
                # Examine the agent.
                params[:target] = params[:agent]
            elsif params[:target]
                Commands.find_objects(core, params, :target => [:grasped, :worn, :stashed, :position, :body])
            else
                # Assume the player wants a broad overview of what he can see, describe the room
                params[:target] = params[:agent].absolute_position
            end
        end
    end

    module Consume
        def self.stage(core, params)
            params[:target_type_class] = (params[:agent].class_info[:consumes] || core.db.info_for(params[:command], :target))
            Commands.find_objects(core, params, :target => [:inventory, :position])

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
            params[:target].destroy(agent)
        end
    end

    module Get
        def self.stage(core, params)
            Commands.find_objects(core, params, :target => [:position, :stashed, :worn])
            raise(MissingObjectExtensionError, "Agents must have an inventory to pick things up") unless params[:agent].uses?(Equipment)
        end

        def self.do(core, params)
            params[:agent].stash(params[:target])
        end
    end

    module Stash
        def self.stage(core, params)
            Commands.find_objects(core, params, :target => [:grasped, :worn, :position])
        end

        def self.do(core, params)
            params[:agent].stash(params[:target])
        end
    end

    module Drop
        def self.stage(core, params)
            Commands.find_objects(core, params, :target => [:inventory])
        end

        def self.do(core, params)
            params[:target].move_to(params[:agent].absolute_position)
        end
    end

    module Equip
        def self.stage(core, params)
            Commands.find_objects(core, params, :target => [:grasped, :stashed])
            # TODO - take 'on' preposition that establishes destination
#            Commands.find_objects(core, params, :destination => [:body])
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
            Commands.find_objects(core, params, :target => [:worn])
#            Commands.find_objects(core, params, :destination => [:body])
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
            unless params[:destination]
                raise(AmbiguousCommandError, "#{params[:command].title} where? (north, south, east, west)")
            end
            destination = params[:destination]

            position = params[:agent].absolute_position
            raise(NotImplementedError, "You're trapped in a #{position.monicker}!") unless Room === position

            # This method raises an exception if the direction is invalid, so no need to check it
            params[:destination] = position.get_adjacent(destination)
            params[:direction] = destination
        end

        def self.do(core, params)
            params[:agent].move_to(params[:destination], params[:direction])
        end
    end

    module Hide
        def self.stage(core, params)
            if params[:agent].get_aspect(:stealth).properties[:hidden]
                raise(FailedCommandError, "You are already hidden.")
            end
        end

        def self.do(core, params)
            params[:agent].skills[:stealth].properties[:hidden] = true
        end
    end

    module Unhide
        def self.stage(core, params)
            if !params[:agent].get_aspect(:stealth).properties[:hidden]
                raise(FailedCommandError, "You are not in hiding.")
            end
        end

        def self.do(core, params)
            params[:agent].skills[:stealth].properties[:hidden] = false
        end
    end

    module Attack
        def self.stage(core, params)
            # Search for tool and possibly target without complaining about extra parameters.
            params[:no_sanity_check] = true
            if params[:tool]
                Commands.find_objects(core, params, :tool => [:grasped])
            end

            if params[:location]
                # Find the target, then search within the target for the location.
                Commands.find_objects(core, params, :target => [:position])
                params.delete(:no_sanity_check)
                Commands.find_objects(core, params, :location => [params[:target]])
            else
                params.delete(:no_sanity_check)
                Commands.find_objects(core, params, :target => [:position])
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

            # Target a random body part if location not specified
            part_targeted = params[:location] || defender.external_body_parts.rand
            result_hash[:subtarget] = part_targeted

            print = part_targeted ? "in the #{part_targeted.monicker}" : ''
            Log.debug("#{attacker.monicker} attacks #{defender.monicker} #{print}")

            if success
                result_hash[:damage] = damage
                defender.damage(damage, attacker, part_targeted)
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
            Commands.find_objects(core, params, :target => [:position, :inventory])

            if params[:target].open?
                raise(FailedCommandError, "#{params[:target].monicker} is already open.")
            elsif !params[:target].is_type?(:openable)
                raise(FailedCommandError, "#{params[:target].monicker} cannot be opened.")
            end
        end

        def self.do(core, params)
            params[:target].properties[:open] = true
        end
    end

    module Close
        def self.stage(core, params)
            Commands.find_objects(core, params, :target => [:position, :inventory])

            if !params[:target].open?
                raise(FailedCommandError, "#{params[:target].monicker} is already closed.")
            elsif !params[:target].is_type?(:openable)
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
                params[:no_sanity_check] = true
                Commands.find_objects(core, params, :receiver => [:position])
            end
        end

        def self.do(core, params)
            message = Message.new(:unit_speaks,
                :agent       => params[:agent],
                :statement   => params[:statement],
                :is_whisper  => false
            )
            message.params[:receiver] = params[:receiver] if params[:receiver]
            locations = [params[:agent].absolute_position]
            Message.dispatch_positional(core, locations, message.type, message.params)
        end
    end

    module Whisper
        def self.stage(core, params)
            params[:no_sanity_check] = true
            Commands.find_objects(core, params, :receiver => [:position])
        end

        def self.do(core, params)
            message = Message.new(:unit_speaks, {
                :agent       => params[:agent],
                :receiver    => params[:receiver],
                :statement   => params[:statement],
                :is_whisper  => true
            })
            if params[:receiver]
                params[:receiver].process_message(message)
            else
                Log.warning("Whisper with no receiver?")
                locations = [params[:agent].absolute_position]
                Message.dispatch_positional(core, locations, message.type, message.params.merge(:statement => ''))
            end
        end
    end

    module Construct
        def self.stage(core, params)
=begin
            Here we need to take some combination of:
                - a target contructable
                - a list of components
                - a technique
                - a tool
                - a location
            and
                a) Return more information about that thing (or query for more information about the intention)
                b) Link those things into a recipe and prepare to construct it
=end
            raise(MissingObjectExtension, "Only creatures with skill can construct objets") unless params[:agent].uses?(HasAspects)
            Log.debug("#{params[:agent].monicker} is attempting to #{params[:command]} an object")

            raise(MissingProperty, "What do you want to #{params[:command]}?") unless params[:target]

            # If the player has a goal of what they want to make in mind, find the recipes for that thing and then see if the rest of the information given by the player is enough to establish which recipe they want to use
            Log.debug("Target provided - #{params[:target].inspect}")
            # Verify that the target is a :constructed
            raise(NoMatchError, "#{params[:target].inspect} is not a constructable type") unless core.db.is_type?(params[:target], :constructed)

            # Find a recipe (or throw an exception if there's a problem)
            params[:recipe] = find_recipe(core, params)

            # Now we have to check that the player actually has access to all of the stuff in the params
            # TODO - Verify that find_objects can deal with abstract object types like :metal
            Commands.find_objects(core, params.merge(:no_sanity_check => true), {
                :location   => [:position], # Location generally refers to something too large to carry
                :tool       => [:inventory], # A tool might be in a hand or in a pocket
            }, [:location, :tool])

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
                # The "constructed" extension ensures that components are removed from the world, quality is computed correctly given the quality of the ingredients, and the creator is assigned
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

        def self.find_recipe(core, params)
            # Get a list of recipes used to make the thing
            # TODO - Use player knowledge of recipes here
            # TODO - Include raws that are "called" other things
            #  (Example: A "hood" is actually a head_armor made of cloth, but "hood" isn't an entry in the raws)
            recipes = core.db.info_for(params[:target], :recipes)
            Log.debug(["#{recipes.size} recipes found for #{params[:target].inspect} - ", recipes])
            failure_string = "You don't know how to make a #{params[:target]}"
            raise(FailedCommandError, "#{failure_string}.") if recipes.empty?

            # Begin filtering the recipes based on parameters

            # Find recipes that use the "technique" given by the command
            failure_string.sub!("make", params[:command].to_s)
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
                params[:components].each do |component|
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
                    if matches.size > 1
                        Log.debug("Multiple matches found for recipe requirement #{requirement}")
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
            raise(NoMatchError, "It is unclear what available materials should be used to #{params[:command]} a #{params[:target]}") if recipe_map.empty? || recipe_map.size > 1
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
