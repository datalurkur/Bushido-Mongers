module Commands
    class << self
        def do(core, command, params)
            unless core.db.has_type?(command)
                raise "I don't know how to #{command}"
            end

            invocation = core.db.info_for(command, :invocation)
            mod        = invocation.to_caml.to_const(Commands)

            SharedObjectExtensions.check_required_params(params, [:agent])
            mod.do(core, params)

            # Return the resolved parameters
            params
        end

        def resolve(params, types, core, command)
            types.each do |type|
                params[type] = lookup_object(params[type], params[:agent], core.db.info_for(command, type))
            end
        end

        def lookup_object(object, agent, type_class)
            return object if (BushidoObject === object)

            unless type_class
                Log.error("Parameter specified for a command that has no type for that parameter")
                raise "Command error for parameter #{object}"
            end

            potentials = case type_class
            when :corporeal
                # Types that are objects in the location (targets of attacks, conversation, etc)
                # FIXME - With ranged attacks, the object can be in adjacent locations
                agent.position.objects
            else
                raise "Unhandled object type #{type_class}"
            end

            # Sort through the potentials and find out which ones match the query
            potentials = potentials.select do |p|
                p.is_a?(type_class) && p.name.match(/#{object}/i)
            end

            # FIXME: Handle contingencies
            raise "No object #{object} found" if potentials.empty?
            raise "Multiple \"#{object}\'s\" found, be more specific" if potentials.size > 1

            return potentials.first
        end
    end

    module Inspect
        def self.do(core, params)
            if params[:target]
                Commands.resolve(params, [:target], core, :inspect)
            else
                # Assume the player wants a broad overview of what he can see, describe the room
                params[:target] = params[:agent].position
            end
        end
    end

    module Eat
        def self.do(core, params)
            Log.debug("Eating something!")
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
            Commands.resolve(params, [:target], core, :attack)

            Log.debug("#{params[:agent].name} attacks #{params[:target].name}")
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
