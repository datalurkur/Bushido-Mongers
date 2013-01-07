class Descriptor
    def self.describe(object, observer)
        case object
        when BushidoObject; BushidoObjectDescriptor.describe(object, observer)
        when Room;          RoomDescriptor.describe(object, observer)
        when Array;         object.compact.collect { |o| Descriptor.describe(o, observer) }
        when Symbol,String; object
        when Hash
            h = {}
            object.each do |k,v|
                next if v.nil?
                h[k] = Descriptor.describe(v, observer)
            end
            h
        else;               raise "Indescribable class #{object.class}"
        end
    end

    class BushidoObjectDescriptor
        def self.describe(object, observer)
            # FIXME - Take the observer into account
            d = {
                :type => :object
            }

            d[:name]     = object.name if object.is_a?(:named)
            d[:monicker] = (d[:name] || d[:type])
            # FIXME - Add more things
        end
    end

    class RoomDescriptor
        def self.describe(room, observer)
            {
                :type      => :room,
                :name      => room.name,
                :keywords  => room.keywords,
                :objects   => room.objects.collect(&:monicker),
                :exits     => room.connected_directions,
            }
        end
    end
end