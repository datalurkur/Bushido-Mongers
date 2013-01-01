module Commands
    def self.do(core, command, params)
        invocation = core.db.info_for(command, :invocation)
        mod        = invocation.to_caml.to_const(Commands)
        mod.do(core, params)
    end

    module Eat
        def self.do(core, params)
            Log.debug("Eating something!")
        end
    end

    module Attack
        def self.do(core, params)
            SharedObjectExtensions.check_required_params(params, [:attacker, :defender])
            Log.debug("#{params[:attacker].name} attacks #{params[:defender].name}")
            Message.dispatch(core, :unit_attacks, {
                :attacker      => params[:attacker],
                :defender      => params[:defender],
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
