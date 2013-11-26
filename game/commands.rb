require './util/log'
require './util/timer'

module Commands
    class << self
        def get_command_module(core, command)
            unless core.db.static_types_of(:command).include?(command)
                raise(InvalidCommandError, "Command #{command.to_s.inspect} not found.")
            end

            invocation = core.db.info_for(command, :invocation) || command
            invocation.to_caml.to_const(Commands)
        end

        def stage(core, params)
            raise(ArgumentError, "No command given") unless params[:command]
            raise(ArgumentError, "An agent must be present for a command to be staged") unless params[:agent]
            mod = get_command_module(core, params[:command])
            mod.stage(core, params)
            params
        end

        def do(core, params)
            raise(ArgumentError, "No command given") unless params[:command]
            mod = get_command_module(core, params[:command])
            mod.do(core, params) if mod.respond_to?(:do)
        end

        # Examine the params and command info to establish how to search for the object.
        def filter_for_key(core, params, key, object_type = nil)
            object_string = nil
            if core.db.has_type?(params[key])
                object_type   ||= params[key]
            else
                object_string ||= params[key]
            end

            object_type   ||= core.db.info_for(params[:command], key)
            adjectives      = params[(key.to_s + "_adjs").to_sym] || []

            params[:agent].filter_for(object_type, object_string, adjectives)
        end

        # Requires standard param values: agent, command, and the given key.
        def find_object_for_key(core, params, key, object_type = nil, locations = [:all], optional = [])
            if params[key].nil?
                Log.warning("Finding object for nil parameter #{key.inspect}")
            end

            params[key] = params[:agent].find_object(locations, filter_for_key(core, params, key, object_type))
            Log.debug("Found #{key}: #{params[key].monicker}", 6)

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

        metered :verify_params, :find_object_for_key, :find_for_key, :do, :stage
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
                Commands.find_object_for_key(core, params, :location)

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
                    Commands.find_object_for_key(core, params, :target)
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
            Commands.find_object_for_key(core, params, :target, target_class, [:inventory, :position])

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
            Commands.find_object_for_key(core, params, :target, nil, [:position, :stashed, :worn])
        end

        def self.do(core, params)
            params[:agent].stash(params[:target])
        end
    end

    module Stash
        def self.stage(core, params)
            raise(MissingObjectExtensionError, "Must have an inventory to pick things up!") unless params[:agent].uses?(Equipment)
            Commands.find_object_for_key(core, params, :target, nil, [:position, :stashed, :worn])
        end

        def self.do(core, params)
            params[:agent].stash(params[:target])
        end
    end

    module Drop
        def self.stage(core, params)
            raise(MissingObjectExtensionError, "Must have an inventory to pick things up!") unless params[:agent].uses?(Equipment)
            Commands.find_object_for_key(core, params, :target, nil, [:inventory])
        end

        def self.do(core, params)
            params[:target].set_position(params[:agent].absolute_position, :internal)
        end
    end

    module Equip
        def self.stage(core, params)
            Commands.find_object_for_key(core, params, :target, nil, [:grasped, :stashed])
            # TODO - take 'on' preposition that establishes destination
            #Commands.find_object_for_key(core, params, :destination, nil, [:external])
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
            Commands.find_object_for_key(core, params, :target, nil, [:worn])
            # TODO - take 'on' preposition that establishes destination
            #Commands.find_object_for_key(core, params, :destination, nil, [:external])
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
                Commands.find_object_for_key(core, params, :tool, nil, [:grasped])
            end

            Commands.find_object_for_key(core, params, :target)
            # Search within the target for the location, if it exists.
            if params[:location]
                Commands.find_object_for_key(core, params, :location, nil, [params[:target]])
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
            Commands.find_object_for_key(core, params, :target, nil, [:position, :inventory])

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
            Commands.find_object_for_key(core, params, :target, nil, [:position, :inventory])

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
                Commands.find_object_for_key(core, params, :receiver, nil, [:position], [:statement])
            end
        end

        def self.do(core, params)
            params[:agent].say(params[:receiver], params[:statement], true)
        end
    end

    module Whisper
        def self.stage(core, params)
            # Look for receiver. We should probably set it to :self or something otherwise.
            Commands.find_object_for_key(core, params, :receiver, nil, [:position], [:statement])
        end

        def self.do(core, params)
            params[:agent].whisper(params[:receiver], params[:statement], true)
        end
    end

    module Ask
        def self.stage(core, params)
            Commands.find_object_for_key(core, params, :receiver, nil, [:position])
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
            raise(MissingProperty, "What do you want to #{params[:command]}?") unless params[:target]
            # Verify that the target is :made
            raise(NoMatchError, "#{params[:target]} cannot be made.") unless core.db.has_type?(params[:target]) && core.db.is_type?(params[:target], :made)

            # If the player has a goal of what they want to make in mind, find the recipes for that thing and then see if the rest of the information given by the player is enough to establish which recipe they want to use
            Log.debug("#{params[:agent].monicker} is attempting to #{params[:command]} a #{params[:target]}")

            # TODO - find a better place for this?
            params[:components] = Array(params[:components]) if params[:components]

            # Find a recipe (or throw an exception if there's a problem)
            params[:recipe] = get_recipe(core, params)
            # get_recipe also fills params[:components] with actual local objects,
            # so we have enough information to construct something!
        end

        # TODO - should pull out the tool used, if applicable.
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

                Log.debug("#{params[:agent].monicker} has #{params[:command]}ed a #{quality} (#{quality_value}) #{params[:target]}")
            else
                # Failed!  Destroy the components
                params[:components].each do |component|
                    component.destroy(params[:agent])
                end
                Log.debug("#{params[:agent].monicker} flubbed an attempt to #{params[:command]} a #{params[:target]}")
            end
        end

        # Given a type_list, find each matching object locally, ignoring
        # items already in the manifest.
        def self.find_components(agent, type_list, manifest)
            components = type_list.map do |type_class|
                matches = agent.filter_objects([:grasped, :stashed], :type => type_class)
                matches.reject! { |o| manifest.include?(o) }
                if matches.empty?
                    raise(FailedCommandError, "You don't have enough #{type_class}.")
                else
                    manifest << matches.first
                    matches.first
                end
            end
            components
        end

        def self.check_recipe(params, recipe, manifest)
            if params[:components]
                # Verify that specified components meet recipe component requirements
                pc = params[:components]
                rc = recipe[:components]
                raise(FailedCommandError, "Too many components specified.") if pc.size > rc.size
                raise(FailedCommandError, "Can't specify partial components yet.") if pc.size < rc.size

                # N.B. At this point pc is local BOBs while rc is still a list of types.
                # If all the components specified match a recipe component type, we've found a working
                # permutation and thus a match.
                match = false
                pc.permutation do |perm|
                    perm_match = true
                    recipe[:components].each do |r|
                        object = perm.pop
                        if object.matches(:type => r)
                            next
                        else
                            perm_match = false
                            break
                        end
                    end
                    if perm_match
                        match = true
                        break
                    else
                        next
                    end
                end
                raise(FailedCommandError, "Can't reconcile specified components with recipe components.") unless match
            else
                # No components specified. Find items based on the recipe type list.
                # In case of exception in find_components, don't wreck the original manifest.
                local_manifest = manifest
                params[:components] = find_components(params[:agent], recipe[:components], local_manifest)
                manifest = local_manifest
            end

            # Is technique something that can be done by agent?

            # Does the technique have a location? Is that satisfied?
            if recipe[:location] # TODO - should be derived from technique=>skill=>location
                Log.warning("recipe[:location #{recipe[:location]}")
                if params[:location]
                    matches = params[:agent].filter_objects([:position], Commands.filter_for_key(core, params, :location))
                    matches.select! { |o| object.matches(:type => recipe[:location]) }
                elsif
                    matches = params[:agent].filter_objects([:position], :type => recipe[:location])
                end
                matches.reject! { |o| manifest.include?(o) }
                raise(FailedCommandError, "Not at #{recipe[:location]}.") if matches.empty?
                params[:location] = matches.first
            end

            # Was there a tool specified?
            if recipe[:tool] # TODO - should be derived from technique=>skill=>tool
                if params[:tool]
                    matches = params[:agent].filter_objects([:grasped, :stashed], Commands.filter_for_key(core, params, :tool))
                    matches.select! { |o| object.matches(:type => recipe[:tool]) }
                else
                    matches = params[:agent].filter_objects([:grasped], :type => recipe[:location])
                end
                matches.reject! { |o| manifest.include?(o) }
                raise(FailedCommandError, "Can't find the necessary #{recipe[:tool]}.") if matches.empty?
                params[:location] = matches.first
            end

            # If nothing has errored out, the recipe is found and can be used.

            return recipe
        end

        # TODO: Send the failure messages back to be formatted by Words.
        # FIXME - Doesn't properly check for technique, location and tool.
        # They need to be moved to the skill for this to happen properly.
        def self.get_recipe(core, params)
            # Get all recipes for the intended object.
            recipes = core.db.info_for(params[:target], :recipes)
            matching_recipe = nil
            # The manifest stores all local components already selected for use in the recipe,
            # so they aren't selected twice.
            manifest    = []

            # The user has specified a list of components to use. Replace with world objects.
            if params[:components]
                params[:components] = find_components(params[:agent], params[:components], manifest)
            end

            last_error = nil
            recipes.each do |recipe|
                begin
                    if self.check_recipe(params, recipe, manifest)
                        matching_recipe = recipe
                    end
                rescue GameError => e
                    last_error = e
                end
            end

            if matching_recipe
                Log.debug("Found matching recipe #{matching_recipe.inspect}")
                Log.debug([matching_recipe, params[:components]], 6)
                return matching_recipe
            else
                raise(last_error)
            end
        end
    end # module Make
end # module Commands
