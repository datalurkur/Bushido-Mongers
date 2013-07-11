module Transforms
    class << self
        def transform(transformation, core, object, params)
            raise(ArgumentError, "Unknown transformation type #{transformation.inspect}") unless respond_to?(transformation)
            method(transformation).call(core, object, params)
        end

        def acid_burn(core, object, params)
            Log.debug("Burning #{object.monicker} with acid")

            if object.uses?(Composition)
                object.apply_transform(:acid_burn, params)
            elsif object.uses?(Atomic)
                # TODO - Make this a more interesting calculation
                # For now, we just take the difference between the hardness and the magnitude of the acid and scale the damage by that difference (exponentially)
                acidity_factor = object.class_info[:hardness] - params[:magnitude]
                damage = 0.1 ** acidity_factor
                object.damage(damage, nil)
            else
                Log.warning("Unable to apply targeted transform to an object that is neither atomic nor a composition")
            end

            core.destroy_flagged
            object
        end

        def animate(core, object, params)
            unless object.uses?(Corporeal)
                Log.warning("Animate is a transformation intended to be used on corporeal objects")
                return
            end

            if object.alive?
                Log.warning("#{object.monicker} would appear to already be alive")
                return
            end

            Message.dispatch_positional(core, [object.absolute_position], :unit_animated, {
                :agent    => params[:agent],
                :target   => object,
                :location => object.absolute_position
            })

            object.setup_extension(Perception, params)
            object.setup_extension(Karmic, params)
        end

        def kill(core, object, params)
            unless object.uses?(Corporeal)
                Log.warning("Death is a transformation intended to be used on corporeal objects")
                return
            end

            unless object.alive?
                Log.warning("#{object.monicker} would appear to already be dead")
                return
            end

            Message.dispatch_positional(core, [object.absolute_position], :unit_killed, {
                :agent    => params[:agent],
                :target   => object,
                :location => object.absolute_position
            })
            post_death_name = if object.uses?(Karmic) && object.name
                object.name + "'s corpse"
            else
                object.get_type.text + " corpse"
            end
            object.set_called(post_death_name)
            [Character,Karmic,NpcBehavior,Perception].each do |ext|
                object.remove_extension(ext)
            end
            object
        end
    end
end
