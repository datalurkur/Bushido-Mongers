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
            #FIXME
            raise(NotImplementedError)
        end

        def self.do(core, params)
            #FIXME
            raise(NotImplementedError)
        end
    end
end
