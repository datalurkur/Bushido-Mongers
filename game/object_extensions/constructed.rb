require './util/log'

module Constructed
    class << self
        def at_creation(instance, params)
            # Remove component items from the world
            params[:components].each do |component|
                # This next is only necessary if the component has been created
                # ex nihilo, which happens sometimes.
                next unless component.has_position?
                component.relative_position.remove_object(component)
            end

            # Created object quality depends on the quality of its components as well
            avg_component_quality = params[:components].inject(0.0) { |s,i|
                s + Quality.index(i.is_type?(:constructed) ? i.quality : :standard)
            } / params[:components].size
            quality = (Quality.index(params[:quality]) + avg_component_quality) / 2.0
            quality_level = Quality.levels[quality.ceil]

            instance.set_property(:quality,    quality_level)
            instance.set_property(:incidental, params[:components])
        end
    end
end
