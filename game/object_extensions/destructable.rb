module Destructable
    class << self
        def pack(instance); {:integrity => instance.integrity}; end

        def unpack(core, instance, raw_data)
            raise(MissingProperty, "Destructable data corrupted") unless raw_data[:integrity]
            instance.integrity = raw_data[:integrity]
        end

        def at_creation(instance, params)
            actual_size = Size.adjust(instance.class_info[:typical_size], params[:relative_size] || Size.standard)
            instance.properties[:size]    = actual_size
            instance.properties[:weight] *= Size.value_of(actual_size)

            integrity = instance.properties[:weight]  *
                        instance.properties[:density]
            instance.integrity = integrity
        end
    end

    attr_accessor :integrity
end
