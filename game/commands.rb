module Commands
    class << self
        def do(core, command, params)
            invocation = core.db.info_for(command, :invocation)

            # In the case of player commands, these values might not be filled in but will be symbols we have to search for
            params.each do |k,v|
                next if v.nil?
                next if BushidoObject === v

                Log.debug("Performing intelligent parameter lookup on param #{k} with value #{v}")
                case k
                when :target
                    case invocation
                    when :move; params[:target] = v
                    else        params[:target] = find_object(core, command, params[:agent], params[:target], :target)
                    end
                when :tool
                    # The tool is likely in the agent's inventory, but possibly in the location
                    # FIXME
                when :material
                    # The material is likely in the agent's inventory, but possibly in the location
                    # FIXME
                when :location
                    # The location is an object within a place, so search this room for objects that match
                    # FIXME
                end
            end

            mod             = invocation.to_caml.to_const(Commands)
            params[:result] = mod.do(core, params)

            # Return the parsed parameters
            params
        end

        def find_object(core, command, agent, name, type)
            klass = core.db.info_for(command, type)
            unless klass
                Log.warning("Parameter specified for a command that has no type for that parameter (#{type})")
                return nil
            end

            potentials = case klass
            when :corporeal
                # Types that are occupants in the location (targets of attacks, conversation, etc)
                # FIXME - With ranged attacks, the object can be in adjacent locations
                agent.position.occupants
            else
                raise "Unhandled object type #{klass}"
            end

            # Sort through the potentials and find out which ones match the query
            potentials = potentials.select do |occupant|
                occupant.is_a?(klass) && occupant.name.match(/#{name}/i)
            end

            # FIXME: Handle contingencies
            raise "No object #{name} found" if potentials.empty?
            raise "Be more specific" if potentials.size > 1

            potentials.first
        end
    end

    module Eat
        def self.do(core, params)
            Log.debug("Eating something!")
        end
    end

    module Move
        def self.do(core, params)
            Log.debug(params)
            SharedObjectExtensions.check_required_params(params, [:agent, :target])
            params[:agent].move(params[:target])
        end
    end

    module Attack
        def self.do(core, params)
            SharedObjectExtensions.check_required_params(params, [:agent, :target])
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
