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
            mod = get_command_module(core, command)
            unless params[:agent] && params[:command]
                raise(ArgumentError, "An agent and a command must be present for a command to be staged")
            end
            mod.stage(core, params)
            # Return the resolved parameters
            params.merge(:command => command)
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
        def find_objects(core, params, filters)
            missing_params = []
            filters.keys.each do |req|
                missing_params << req unless params[req]
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
                        clarification_string += " where"
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
            list << params[:agent].attribute_list.collect { |name| params[:agent].attribute(name) }
            list << params[:agent].skill_list.collect     { |name| params[:agent].skill(name) }
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
            if params[:agent].skill(:hide).properties[:hidden]
                raise(FailedCommandError, "You are already hidden.")
            end
        end

        def self.do(core, params)
            params[:agent].skill(:hide).properties[:hidden] = true
        end
    end

    module Unhide
        def self.stage(core, params)
            unless params[:agent].skill(:hide).properties[:hidden]
                raise(FailedCommandError, "You are not in hiding.")
            end
        end

        def self.do(core, params)
            params[:agent].skill(:hide).properties[:hidden] = false
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

            if attacker.has_skill?(skill)
                success = attacker.opposed_check(skill, Difficulty.standard, defender, :defense)
            else
                # TODO - generate skill on attacker
                Log.debug("#{skill.inspect} doesn't exist for #{attacker.monicker}!")
                success = (rand > Difficulty.value_of(Difficulty.standard))
            end

            # Target a random body part if location not specified
            part_targeted = params[:location] || defender.external_body_parts.rand
            result_hash[:subtarget] = part_targeted

            print = part_targeted ? "in the #{part_targeted.monicker}" : ''
            Log.debug("#{attacker.monicker} attacks #{defender.monicker} #{print}")

            if success
                result_hash[:damage] = damage
                defender.damage(damage, attacker, part_targeted)
            end

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
            # Look for receiver in the room.
            if params[:receiver]
                Commands.find_objects(core, params, :receiver => [:position])
            end
        end

        def self.do(core, params)
            if params[:receiver]
                # TODO - send message only to receiver, for whisper
            else
                locations = [params[:agent].absolute_position]
                Message.dispatch_positional(core, locations, :unit_acts, {
                    :agent       => params[:agent],
                    :action      => :say,
                    :location    => locations.first,
                    :action_hash => {:receiver => params[:receiver], :statement => params[:statement]}
                })
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
            Log.debug(["Player is attempting to construct an object with params", params])

            if params[:target]
                # If the player has a goal of what they want to make in mind, find the recipes for that thing and then see if the rest of the information given by the player is enough to establish which recipe they want to use
                Log.debug("Target provided - #{params[:target].inspect}")

                # Find a recipe (or throw an exception if there's a problem)
                params[:recipe] = find_recipe(core, params)

                # Now we have to check that the player actually has access to all of the stuff in the params
                # TODO - Verify that find_objects can deal with abstract object types like :metal
                Commands.find_objects(core, params, {
                    :location   => [:position], # Location generally refers to something too large to carry
                    :tool       => [:inventory, :body], # A tool might be in a hand or in a pocket
                    :components => [:inventory, :body],
                })

                # Verify that the player has the skill needed to construct the thing
                # FIXME

                # TODO - Add something like minimum skill levels

                # We have enough information to construct something!
            else
                # If the player gives only components / a technique / a location, provide some information about what they might possibly do with those things
                Log.debug("Providing more information given no target")
                # FIXME
                raise(NotImplementedError)
            end
        end

        def self.do(core, params)
            #FIXME
            raise(NotImplementedError)
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
            if params[:technique]
                failure_string.sub!("make", params[:technique])
                recipes.select! { |r| r[:technique] == params[:technique] }
                raise(NotImplementedError)
                raise(FailedCommandError, "#{failure_string}, perhaps try a different technique.") if recipes.empty?
            end
            if params[:location]
                failure_string += " at a #{params[:location]}"
                recipes.select! { |r| r[:location] == params[:location] }
                raise(NotImplementedError)
                raise(FailedCommandError, "#{failure_string}, perhaps try a different location.") if recipes.empty?
            end
            if params[:tool]
                failure_string += " with a #{params[:tool]}"
                recipes.select! { |r| r[:tool] == params[:tool] }
                raise(NotImplementedError)
                raise(FailedCommandError, "#{failure_string}, perhaps try a different tool.") if recipes.empty?
            end
            if params[:components]
                failure_string += " using #{params[:components].dup.insert(-2, "and").join(", ")}"
                params[:components].each do |component|
                    recipes.select! { |r| r[:components].include?(component) }
                end
                raise(NotImplementedError)
                raise(FailedCommandError, "#{failure_string}, perhaps try different components.") if recipes.empty?
            end

            if recipes.size > 1
                # The parameters are ambiguous
                distinct_locations  = recipes.collect { |r| r[:location]  }.uniq
                distinct_tools      = recipes.collect { |r| r[:tool]      }.uniq
                distinct_techniques = recipes.collect { |r| r[:technique] }.uniq
                # FIXME - Return some interesting information about *why* the command fails here
                # Example: If all of the recipes have the same tool, ask the player to be more specific with the components (since the tool probably isn't what needs to change)
                raise(NotImplementedError)
            end

            recipe = recipes.first

            # FIXME - Add logging

            # If we had enough parameters to select a recipe, but some were left blank, fill in the missing pieces in the parameters before object lookup
            [:tool, :location, :technique].each do |key|
                params[key] ||= recipe[key] if recipe[key]
            end
            # Components are a bit funky, since we have to care about incomplete component lists, and generic components ("metal" instead of "iron")
            missing_components = []
            unused_components = params[:components].dup
            sorted_components = recipe[:components].sort do |x,y|
                core.db.minimum_depth_of(x) <=> core.db.minimum_depth_of(y)
            end
            sorted_components.each do |component|
                match = nil
                unused_components.each do |unused|
                    if core.db.is_type?(unused, component)
                        match = unused
                        break
                    end
                end
                if match
                    unused_components.delete(match)
                else
                    missing_components << component
                end
            end

            unless unused_components.empty?
                # The user specified some components that can't be used
                raise(FailedCommandError, "Some components could not be used")
            end
            params[:components].concat(missing_components)

            return recipe
        end
    end
end
