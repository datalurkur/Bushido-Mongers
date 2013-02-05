require './util/log'

module Constructed
    class << self
        def at_creation(instance, params)
            Log.debug(["Constructing a #{instance.monicker} with params", params], 8)
            components = params[:components]
            quality    = params[:quality]
            randomized = false
            if params[:randomize]
                unless components
                    randomized = true
                    components = instance.get_random_components(params)
                end
                quality ||= Quality.random
            else
                raise(ArgumentError, ":components is a required parameter for non-random equipment.") unless components
                raise(ArgumentError, ":quality is a required parameter for non-random equipment.") unless quality
            end

            # Remove component items from the world
            components.each do |component|
                # This next is only necessary if the component has been created
                # ex nihilo, which happens sometimes.
                next unless component.has_position?
                component.relative_position.remove_object(component)
            end

            # Created object quality depends on the quality of its components as well
            avg_component_quality = components.inject(0.0) { |s,i|
                s + Quality.index_of(i.is_type?(:constructed) ? i.quality : :standard)
            } / components.size
            quality_value = (Quality.index_of(quality) + avg_component_quality) / 2.0
            quality_level = Quality.value_at(Quality.clamp_index(quality_value.ceil))

            instance.set_property(:quality,    quality_level)
            instance.set_property(:incidental, components)
        end
    end

    def get_random_components(params)
        p = params.reject { |k,v| k == :components || k == :quality || k == :position }
        # Choose a random recipe
        recipe = class_info(:recipes).rand
        recipe[:components].collect do |component|
            @core.db.create(@core, @core.db.random(component), p)
        end
    end
end
