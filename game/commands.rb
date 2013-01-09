module Commands
    class << self
        def do(core, command, params)
            unless core.db.has_type?(command)
                raise "I don't know how to #{command}"
            end
            if core.db.is_type?(command, :command_alias)
                alias_info = core.db.info_for(command)

                # Translate any derived parameters
                derived_params = {}
                [:target, :location, :tool].each do |key|
                    derived_key = "derived_#{key}".to_sym
                    if alias_info[derived_key]
                        derived_params[key] = params[alias_info[derived_key]]
                    end
                end
                derived_params.reject! { |k,v| v.nil? }

                # Set the new parameters and proper command
                params.merge!(derived_params)
                command = alias_info[:aliases]
            end

            invocation = core.db.info_for(command, :invocation)
            mod        = invocation.to_caml.to_const(Commands)

            SharedObjectExtensions.check_required_params(params, [:agent])
            mod.do(core, params)

            # Return the resolved parameters
            params.merge(:command => command)
        end

        def filter_objects(agent, location, type=nil, name=nil)
            case location
            when :position
                agent.position.objects.select do |p|
                    (type ? p.is_type?(type) : true) &&
                    (name ? p.monicker.match(/#{name}/i) : true)
                end
            # when :inventory
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
        def self.do(core, params)
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
    end

    module Consume
        def self.do(core, params)
            SharedObjectExtensions.check_required_params(params, [:target])

            agent        = params[:agent]
            edible_types = (agent.class_info(:consumes) || :consumable)
            params[:target] = Commands.lookup_object(agent, edible_types, params[:target], [:inventory, :position])

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

    module Move
        def self.do(core, params)
            SharedObjectExtensions.check_required_params(params, [:target])

            # The target is a location direction and doesn't need to be looked up
            params[:agent].move(params[:target])
        end
    end

    module Attack
        def self.do(core, params)
            SharedObjectExtensions.check_required_params(params, [:target])

            # The target is an object and needs to be resolved
            params[:target] = Commands.lookup_object(
                params[:agent],
                core.db.info_for(:attack, :target),
                params[:target],
                [:position]
            )

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
        def self.do(core, params)
            Log.debug("Constructing something!")
        end
    end
end
