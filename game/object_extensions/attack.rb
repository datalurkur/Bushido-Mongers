module Attack
    class << self
        def at_creation(instance, params)
            reqs = [:attacker, :defender]
            SharedObjectExtensions.check_required_params(params, reqs)
            reqs.each do |param|
                instance.set_property(param, params[param])
            end
        end
    end

    def on_command
        Log.debug("#{attacker.name} attacks #{defender.name}")
        Message.dispatch(@core, :unit_attacks, {
            :attacker      => attacker,
            :defender      => defender,
            :chance_to_hit => 1.0, # FIXME
            :damage        => 5,   # FIXME
        })
    end
end
