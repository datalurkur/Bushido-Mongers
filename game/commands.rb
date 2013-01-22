require './util/log'

module Commands
    class << self
        def get_command_module(core, command)
            unless core.db.has_type?(command)
                raise "I don't know how to #{command}"
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
            mod.do(core, params)
        end

        def filter_objects(agent, location, type=nil, name=nil)
            case location
            when :position
                # A player tied to a long pole can still grab apples
                agent.absolute_position.objects.select do |object|
                    object.matches(:type => type, :name => name)
                end
            when :inventory
                return [] unless agent.uses?(Equipment)
                # First, look through the basic items.
                list = (agent.all_grasped_objects + agent.all_worn_objects).select do |object|
                    object.matches(:type => type, :name => name)
                end
                # Then try searching in all the containers.
                # First, look through the basic items.
                list += agent.containers_in_inventory.select do |cont|
                    cont.internal_objects(true) do |object|
                        object.matches(:type => type, :name => name)
                    end
                end
#            when :body
                # FIXME: Search through all resident corporeals' bodies.
#                []
            else
                Log.warning("#{location} lookups not implemented")
                []
            end
        end

        def lookup_object(agent, type_class, object, locations)
            return object if (BushidoObject === object)

            # Sort through the potentials and find out which ones match the query
            potentials = []
            locations.each do |location|
                results = filter_objects(agent, location, type_class, object)
                potentials.concat(results)
                break unless potentials.empty?
            end

            case potentials.size
            when 0
                raise "No object #{object} found"
            when 1
                return potentials.first
            else
                # TODO - We should try re-searching here based on other descriptive information/heuristics.
                raise "Ambiguous: There are too many #{type_class} objects!"
            end
        end

        # Requires standard param values: agent, command.
        # Requires a parameter value :needed, which is a hash:
        #  key: parameter to lookup.
        #  value: where to look for the object, in order.
        # Takes optional parameter value :'key'_type_class, where 'key' is a key of :needed.
        def find_objects(core, params)
            locations = Array(locations)
            SharedObjectExtensions.check_required_params(params, params[:needed].keys + [:agent, :command])

            params[:needed].each do |p, lookup_locs|
                params[p] = Commands.lookup_object(
                    params[:agent],
                    params[:"#{p}_type_class"] || core.db.info_for(params[:command], p),
                    params[p],
                    lookup_locs
                )
            end
        end
    end

    module Inspect
        def self.stage(core, params)
            Log.debug(params)
            if params[:target] == :self || params[:target] == params[:agent].monicker
                # Examine the agent.
                # TODO - there should be multiple ways to specify this.
                params[:target] = params[:agent]
            elsif params[:target]
                Commands.find_objects(core, params.merge(:needed => {:target => [:inventory, :position, :body]}))
            else
                # Assume the player wants a broad overview of what he can see, describe the room
                params[:target] = params[:agent].absolute_position
            end
        end

        def self.do(core, params); end
    end

    module Consume
        def self.stage(core, params)
            params[:target_type_class] = (params[:agent].class_info(:consumes) || core.db.info_for(params[:command], :target))
            Commands.find_objects(core, params.merge(:needed => {:target => [:inventory, :position]}))
        end

        def self.do(core, params)
            agent = params[:agent]
            if agent.class_info(:on_consume)
                eval agent.class_info(:on_consume)
            elsif params[:target].is_type?(:consumable)
                # Do normal consumption
                Log.info("#{agent.monicker} eats #{params[:target].monicker} like a normal person.")
            else
                raise "#{agent.monicker} doesn't know how to eat a #{params[:target].type}"
            end
            params[:target].destroy(agent)
        end
    end

    module Get
        def self.stage(core, params)
            Commands.find_objects(core, params.merge(:needed => {:target => [:position, :inventory]}))
        end

        def self.do(core, params)
            params[:agent].stash(params[:target])
        end
    end

    module Drop
        def self.stage(core, params)
            Commands.find_objects(core, params.merge(:needed => {:target => [:inventory]}))
        end

        def self.do(core, params)
            params[:target].move_to(params[:agent].absolute_position)
        end
    end

    module Move
        def self.stage(core, params)
            SharedObjectExtensions.check_required_params(params, [:target])

            position = params[:agent].absolute_position
            raise "You're trapped in a #{position.monicker}!" unless Room === position

            # This method raises an exception if the direction is invalid, so no need to check it
            params[:target] = position.get_adjacent(params[:target])
        end

        def self.do(core, params)
            params[:agent].move_to(params[:target])
        end
    end

    module Hide
        def self.stage(core, params); end

        def self.do(core, params)
            if params[:agent].get_property(:hidden)
                raise "You are already hidden."
            else
                params[:agent].set_property(:hidden, true)
            end
        end
    end

    module Unhide
        def self.stage(core, params); end

        def self.do(core, params)
            if params[:agent].get_property(:hidden)
                params[:agent].set_property(:hidden, false)
            else
                raise "You are not in hiding."
            end
        end
    end

    module Attack
        def self.stage(core, params)
            SharedObjectExtensions.check_required_params(params, [:target])

            # The target is an object and needs to be resolved
            params[:needed] = { :target => [:position] }
            Commands.find_objects(core, params.merge(:needed => {:target => [:position]}))
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
        end

        def self.do(core, params)
            #FIXME
        end
    end
end
