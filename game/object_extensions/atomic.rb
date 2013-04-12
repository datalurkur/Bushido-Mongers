module Atomic
    class << self
        def pack(instance)
            {
                :integrity => instance.integrity,
                :size      => instance.size,
                :weight    => instance.weight,
                :value     => instance.value
            }
        end

        def unpack(core, instance, raw_data)
            [:integrity, :size, :weight, :value].each do |key|
                raise(MissingProperty, "Atomic data corrupted") unless raw_data[key]
            end
            instance.integrity = raw_data[:integrity]
            instance.size      = raw_data[:size]
            instance.weight    = raw_data[:weight]
            instance.value     = raw_data[:value]
        end

        def at_creation(instance, params)
            raise(ObjectExtensionCollision, "Composition and Atomic are not compatible object extensions") if instance.uses?(Composition)

            instance.weight = instance.class_info[:typical_weight]
            instance.value  = instance.class_info[:typical_value]

            instance.size = if params[:size]
                # Take the size difference between the given size and the typical size and apply it to the standard size
                relative_size    = Size.adjust(Size.standard, params[:size], instance.class_info[:typical_size])
                instance.weight *= Size.value_of(relative_size)
                instance.value  *= Size.value_of(relative_size)

                params[:size]
            elsif params[:relative_size]
                # Take the difference between the relative size and the standard size and apply it to the typical size
                instance.weight *= Size.value_of(params[:relative_size])
                instance.value  *= Size.value_of(params[:relative_size])

                Size.adjust(instance.class_info[:typical_size], params[:relative_size])
            else
                instance.class_info[:typical_size]
            end

            instance.integrity = instance.weight * instance.class_info[:density]
        end
    end

    attr_accessor :integrity, :size, :weight, :value

    def damage(amount, attacker)
        Log.debug("Atomic #{monicker} taking damage (#{amount})")
        self.integrity -= amount
        if self.integrity <= 0
            Log.debug("#{monicker}'s integrity is reduced to zero")
            @core.flag_for_destruction(self, attacker)
        end
    end
end
