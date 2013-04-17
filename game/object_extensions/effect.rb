module EffectSource
    class << self
        def at_creation(instance, params)
            instance.class_info[:native_effects].each { |e| instance.add_effect_source(e) }
        end
        def at_message(instance, message)
            instance.apply_effect_sources if message.type == :tick
        end
    end

    def add_effect_source(effect)
        if effect_sources.include?(effect)
            Log.warning("#{monicker} is already a source for effect type #{effect}")
            return
        end
        start_listening_for(:tick) if effect_sources.empty?
        # TODO - Consider instantiating effects so that their properties can be modified
        effect_sources << effect
        Log.debug("#{monicker} is now a source for effect type #{effect}", 5)
    end

    def remove_effect_source(effect)
        unless effect_sources.include?(effect)
            Log.warning("#{monicker} is not a source for effect type #{effect}")
            return
        end
        effect_sources.delete(effect)
        stop_listening_for(:tick) if effect_sources.empty?
    end

    def effect_sources;  @effect_sources  ||= []; end
    def applied_windups; @applied_windups ||= {}; end

    def apply_effect_sources
        Log.debug("Applying #{effect_sources.size} effects from #{monicker}", 4)
        effect_sources.each do |effect|
            target_type = @core.db.info_for(effect, :target)
            windup      = @core.db.info_for(effect, :windup)
            wound_up    = []
            targets     = []

            Log.debug("#{monicker} applying #{effect} to all #{target_type} objects", 4)

            # Get a list of targets to which this effect is applied
            if uses?(Composition)
                unless container_classes.include?(target_type)
                    Log.error("Effect target #{target} is unimplemented")
                    return
                end
                targets = container_contents(target_type)
            elsif uses?(Atomic)
                unless target == :incidental
                    Log.warning("Atomic objects only care about incidental effects")
                    return
                end
                targets = [self]
            else
                Log.warning("Effects can only be applied to physically-derived objects (#{monicker} is neither ATomic nor a Composition)")
                targets = []
            end

            # Apply windup to any objects in the effect's influence
            applied_windups[effect] ||= {}
            windups = applied_windups[effect]
            targets.each do |target|
                windups[target] ||= 0 
                windups[target]  += 1
                wound_up << target
                Log.debug("Winding up #{target.monicker} (#{windup - windups[target] + 1} ticks to application)", 5)
            end

            # Remove windups for any objects that have left the effect's influence before the effect triggered
            winddowns = (windups.keys - wound_up)
            winddowns.each { |o| windups.delete(o) }
            Log.debug("#{winddowns.size} targets escaped the windup", 5)

            # Trigger effects
            triggered = []
            windups.each do |target,value|
                if value > windup
                    target.apply_effect(effect)
                    triggered << target
                end
            end

            # Remove windups for effects that have triggered
            triggered.each { |o| windups.delete(o) }
        end
    end
end

module EffectTarget
    class << self
        def at_message(instance, message)
            instance.tick_effects if message.type == :tick
        end
    end

    def apply_effect(effect)
        Log.debug("Applying #{effect} to #{monicker}", 4)
        Log.debug("#{monicker} is already affected by #{effect}", 5) if applied_effects[effect]
        start_listening_for(:tick) if applied_effects.empty?
        applied_effects[effect] = @core.db.info_for(effect).dup
    end

    def applied_effects; @applied_effects ||= {}; end

    def tick_effects
        return if applied_effects.empty?

        finished = []
        applied_effects.each do |effect,info|
            Log.debug("Ticking #{effect} on #{monicker} for #{info[:duration]} more tick(s)", 4)
            info[:duration] -= 1
            finished << effect if (info[:duration] < 0)
            Transforms.transform(info[:transform], @core, self, info)
        end
        finished.each { |e| applied_effects.delete(e) }

        stop_listening_for(:tick) if applied_effects.empty?
    end
end