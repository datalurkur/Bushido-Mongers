require './util/log'

module AdjustableSize
    class << self
        def at_creation(instance, params)
            actual_size = Size.adjust(instance.class_info(:typical_size), params[:relative_size] || Size.standard)
            instance.properties[:size]    = actual_size
            instance.properties[:weight] *= Size.value_of(actual_size)

            # FIXME - Use actual hitpoint values here instead of basing them purely off size
            # Example: Wood is going to have more hitpoints per-size-unit than paper
            instance.properties[:hp]     = 2 ** Size.index_of(actual_size)
        end
    end
end
