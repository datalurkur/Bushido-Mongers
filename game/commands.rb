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
                agent.position.objects.select do |object|
                    object.matches(:type => type, :name => name)
                end
            when :inventory
                # TODO - recursive
                return [] unless core.db.raw_info_for(agent.type)[:uses].include?(Equipment)
                agent.select_inventory do |object|
                    object.matches(:type => type, :name => name)
                end
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

            # FIXME: Handle contingencies
            raise "No object #{object} found" if potentials.empty?

            return potentials.first
        end
    end

    module Inspect
        def self.stage(core, params)
            if params[:target]
                params[:target] = Commands.lookup_object(
                    params[:agent],
                    core.db.info_for(:inspect, :target),
                    params[:target],
                    [:position, :inventory]
                )
            else
                # Assume the player wants a broad overview of what he can see, describe the room
                params[:target] = params[:agent].position
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
            params[:target].destroy
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
        end

        def self.do(core, params)
            # The target is a location direction and doesn't need to be looked up
            params[:agent].move(params[:target])
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
