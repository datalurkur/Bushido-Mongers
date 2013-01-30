# Note to the coder: Be *very* careful when dealing with hashes and arrays.
# In particular, if a BushidoObject sneaks through in such a fashion, it will rain
#  destruction down on you as the message packers / unpackers attempt to infinitely 
#  pack and unpack the core contained within

require "./world/room"

class Descriptor
    def self.describe(object, observer)
        case object
        when BushidoObject; BushidoObjectDescriptor.describe(object, observer)
        when Room;          RoomDescriptor.describe(object, observer)
        when Array;         object.compact.collect { |o| Descriptor.describe(o, observer) }
        when Symbol,String,Fixnum,Float,TrueClass,FalseClass,NilClass; object
        when Hash
            h = {}
            object.each do |k,v|
                next if v.nil?
                h[k] = Descriptor.describe(v, observer)
            end
            h
        else; raise(NotImplementedError, "Cannot describe objects of type #{object.class}.")
        end
    end

    class BushidoObjectDescriptor
        def self.describe(object, observer)
            # FIXME - Take the observer into account
            d = {
                :type => object.type
            }

            d[:name]             = object.name if object.has_property?(:name)
            d[:monicker]         = (d[:name] || d[:type])

            d[:name] = d[:monicker] = :you if observer && d[:monicker] == observer.monicker

            # Collect parent type information
            d[:is_type]          = object.type_ancestry

            # Collect property information
            d[:properties]       = Descriptor.describe(object.properties, observer)
            # Undecided as to whether these are useful to have - lots of duplication
            #d[:class_properties] = Descriptor.describe(object.class_properties, observer)

            # Drop some non-informative values.
            [:incidental, :external, :internal].each do |prop|
                if d[:properties][prop] && d[:properties][prop].empty?
                    d[:properties].delete(prop)
                end
            end

            # FIXME - Add more things

            d
        end
    end

    class RoomDescriptor
        def self.describe(room, observer)
            friendly_name = room.name.gsub(/-\d+$/, '')
            {
                :type      => :room,
                :monicker  => friendly_name.to_sym,
                :zone      => room.zone.type,
                :keywords  => room.keywords,
                :objects   => observer.perceivable_objects_of(room.objects - [observer]).collect(&:monicker),# ,
                :exits     => room.connected_directions,
            }
        end
    end
end
