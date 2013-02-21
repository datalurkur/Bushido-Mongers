require './util/log'

module Commands
    class << self
        def get_command_module(core, command)
            unless core.db.has_type?(command)
                raise(InvalidCommandError, "Command #{command.inspect} not found.")
            end

            invocation = core.db.info_for(command, :invocation)
            invocation.to_caml.to_const(Commands)
        end

        def stage(core, command, params)
            mod = get_command_module(core, command)
            SharedObjectExtensions.check_required_params(params, [:agent])
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
            SharedObjectExtensions.check_required_params(params, filters.keys + [:agent, :command])

            filters.each do |p, lookup_locs|
                params[p] = params[:agent].find_object(
                    params[:"#{p}_type_class"] || core.db.info_for(params[:command], p),
                    params[p],
                    lookup_locs
                )
            end
        end
    end

    module Stats
        def self.stage(core, params)
            # Reach into agent and pull out stat details.
            list = []
            list << params[:agent].attributes.collect { |name| params[:agent].attribute(name) }
            list << params[:agent].skills.collect     { |name| params[:agent].skill(name) }
            params[:target] = list
        end
    end

    module Help
        def self.stage(core, params)
            params[:target] = core.db.types_of(:command)
        end
    end

    module Inspect
        def self.stage(core, params)
            target, adjs = params[:target]
            if target == :self || target == params[:agent].monicker
                # Examine the agent.
                # TODO - there should be multiple ways to specify this.
                params[:target] = params[:agent]
            elsif params[:target]
                Commands.find_objects(core, params, {:target => [:inventory, :position, :body]})
            else
                # Assume the player wants a broad overview of what he can see, describe the room
                params[:target] = params[:agent].absolute_position
            end
        end
    end

    module Consume
        def self.stage(core, params)
            params[:target_type_class] = (params[:agent].class_info(:consumes) || core.db.info_for(params[:command], :target))
            Commands.find_objects(core, params, {:target => [:inventory, :position]})

            unless params[:agent].class_info(:on_consume) || params[:target].is_type?(:consumable)
                raise(FailedCommandError, "#{params[:agent].monicker} doesn't know how to eat a(n) #{params[:target].monicker}")
            end
        end

        def self.do(core, params)
            agent = params[:agent]
            if agent.class_info(:on_consume)
                eval agent.class_info(:on_consume)
            elsif params[:target].is_type?(:consumable)
                # Do normal consumption
                Log.info("#{agent.monicker} eats #{params[:target].monicker} like a normal person.")
            end
            params[:target].destroy(agent)
        end
    end

    module Get
        def self.stage(core, params)
            Commands.find_objects(core, params, {:target => [:position, :inventory]})
        end

        def self.do(core, params)
            params[:agent].stash(params[:target])
        end
    end

    module Drop
        def self.stage(core, params)
            Commands.find_objects(core, params, {:target => [:inventory]})
        end

        def self.do(core, params)
            params[:target].move_to(params[:agent].absolute_position)
        end
    end

    module Move
        def self.stage(core, params)
            SharedObjectExtensions.check_required_params(params, [:destination])

            position = params[:agent].absolute_position
            raise(NotImplementedError, "You're trapped in a #{position.monicker}!") unless Room === position

            # This method raises an exception if the direction is invalid, so no need to check it
            params[:destination] = position.get_adjacent(params[:destination])
        end

        def self.do(core, params)
            params[:agent].move_to(params[:destination])
        end
    end

    module Hide
        def self.stage(core, params)
            if params[:agent].skill(:hide).get_property(:hidden)
                raise(FailedCommandError, "You are already hidden.")
            end
        end

        def self.do(core, params)
            params[:agent].skill(:hide).set_property(:hidden, true)
        end
    end

    module Unhide
        def self.stage(core, params)
            unless params[:agent].skill(:hide).get_property(:hidden)
                raise(FailedCommandError, "You are not in hiding.")
            end
        end

        def self.do(core, params)
            params[:agent].skill(:hide).set_property(:hidden, false)
        end
    end

    module Attack
        def self.stage(core, params)
            SharedObjectExtensions.check_required_params(params, [:target])

            # The target is an object and needs to be resolved
            Commands.find_objects(core, params, {:target => [:position]})
        end

        def self.do(core, params)
            Log.debug("#{params[:agent].monicker} attacks #{params[:target].monicker}")
            Message.dispatch(core, :unit_attacks, {
                :attacker      => params[:agent],
                :defender      => params[:target],
                :chance_to_hit => 1.0, # FIXME
                :damage        => 5,   # FIXME
            })
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
                params[:recipe] = find_recipe(params)

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

        def self.find_recipe(params)
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
