require './util/log'

module Constructed
    class << self
        def at_creation(instance, params)
            Log.debug(["Constructing a #{instance.monicker} with params", params], 8)
            components = params[:components]
            quality    = params[:quality]
            creator    = nil
            randomized = false
            if params[:randomize]
                unless components
                    randomized = true
                    components = instance.get_random_components(params)
                end
                quality ||= Quality.random
            else
                [:creator, :components, :quality].each do |key|
                    raise(ArgumentError, "#{key.inspect} is a required parameter for non-random equipment.") unless params[key]
                end
                instance.set_creator(params[:creator])
            end

            # Remove component items from the world, unless they're freshly created.
            components.each do |component|
                if component.has_position?
                    component.relative_position.remove_object(component)
                end
            end

            # Created object quality depends on the quality of its components as well
            avg_component_quality = components.inject(0.0) { |s,i|
                s + Quality.index_of(i.is_type?(:constructed) ? i.properties[:quality] : Quality.standard)
            } / components.size
            quality_value = (Quality.index_of(quality) + avg_component_quality) / 2.0
            quality_level = Quality.value_at(Quality.clamp_index(quality_value.ceil))

            instance.properties[:quality] = quality_level
            instance.set_container_contents(:incidental, components)
        end

        def pack(instance)
            {:creator => instance.get_creator}
        end

        def unpack(core, instance, raw_data)
            instance.set_creator(raw_data[:creator])
        end
    end

    def get_creator
        @creator
    end

    def set_creator(value)
        @creator = value.uid
    end

    def get_random_components(params)
        p = params.reject { |k,v| k == :components || k == :quality || k == :position }
        # Choose a random recipe
        recipe = class_info[:recipes].rand
        recipe[:components].collect do |component|
            @core.create(@core.db.random(component), p)
        end
    end
end
