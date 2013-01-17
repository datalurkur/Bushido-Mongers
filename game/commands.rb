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
                (agent.all_grasped_objects + agent.all_worn_objects).select do |object|
                    object.matches(:type => type, :name => name)
                end
                # Then try searching in all the containers.
                return [] unless agent.uses?(Equipment)
                # First, look through the basic items.
                agent.containers_in_inventory.select do |cont|
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
                potentials.concat(results) unless results.nil?
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
    end

    module Inspect
        def self.stage(core, params)
            if params[:target]
                # Examine the agent.
                # TODO - there should be multiple ways to specify this.
                params[:target] = params[:agent] if params[:target] == :self

                params[:target] = Commands.lookup_object(
                    params[:agent],
                    core.db.info_for(:inspect, :target),
                    params[:target],
                    [:position, :inventory, :body]
                )
            else
                # Assume the player wants a broad overview of what he can see, describe the room
                params[:target] = params[:agent].absolute_position
            end
        end

        def self.do(core, params); end
    end

    module Consume
        def self.stage(core, params)
            SharedObjectExtensions.check_required_params(params, [:target])

            edible_types    = (params[:agent].class_info(:consumes) || :consumable)
            params[:target] = Commands.lookup_object(params[:agent], edible_types, params[:target], [:inventory, :position])
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
            # Can get all items
            params[:target] = Commands.lookup_object(params[:agent], :item, params[:target], [:position, :inventory])
        end

        def self.do(core, params)
            params[:agent].stash(params[:target])
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

    module Attack
        def self.stage(core, params)
            SharedObjectExtensions.check_required_params(params, [:target])

            # The target is an object and needs to be resolved
            params[:target] = Commands.lookup_object(
                params[:agent],
                core.db.info_for(:attack, :target),
                params[:target],
                [:position]
            )
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
