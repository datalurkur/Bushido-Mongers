module Transforms
    class << self
        def transform(transformation, core, object, params)
            raise(ArgumentError, "Unknown transformation type #{transformation.inspect}") unless respond_to?(transformation)
            method(transformation).call(core, object, params)
        end

        def death(core, object, params)
            Message.dispatch(core, :unit_killed, {
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
