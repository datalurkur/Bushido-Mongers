require './util/log'

module AdjustableWeight
    class << self
        def at_creation(instance, params)
            actual_size = Size.adjust(instance.class_info(:typical_size), params[:relative_size])
            instance.set_property(:size,   actual_size)
            instance.set_property(:weight, instance.weight * Size.value(actual_size))
            instance.set_property(:hp,     2 ** Size.index(actual_size))
        end
    end
end
