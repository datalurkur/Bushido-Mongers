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
                if k == :agent
                    # Drop non-essential agent body information, since it's gigantic
                    h[k][:properties].delete(:incidental)
                end
            end
            h
        else; raise(NotImplementedError, "Cannot describe objects of type #{object.class}.")
        end
    end

    class BushidoObjectDescriptor
        def self.describe(object, observer)
            # TODO - Take the observer into account
            # TODO - SERIOUSLY obfuscate details if object is :hidden
            d = {
                :type => object.get_type,
                :uid  => object.uid,
            }

            d[:name]             = object.name if object.uses?(Karmic)
            d[:monicker]         = (d[:name] || d[:type])

            # Collect parent type information
            d[:is_type]          = object.type_ancestry

            # Collect property information
            d[:properties]       = Descriptor.describe(object.properties, observer)

            if object.uses?(Composition)
                d[:container_contents] = {}
                object.container_classes.each do |prop|
                    contents = object.container_contents(prop)
                    if contents && !contents.empty?
                        d[:container_contents][prop] = contents.collect do |o|
                            Descriptor.describe(o, observer)
                        end
                    end
                end
            end

            # The user doesn't need to know any of this. If they do, we can deal with it on a case-by-case basis.
            [:target_of, :used_in, :can_equip,
             :added_value_container_classes, :preserved_container_classes,
             :container_classes].each do |prop|
                d[:properties].delete(prop)
            end

            if object.is_type?(:aspect)
                # Send an adjective to the user, not a number.
                d[:properties][:adjectives] ||= []
                if object.is_type?(:skill)
                    Log.debug([object.monicker, d[:properties][:intrinsic]])
                    d[:properties][:adjectives] << GenericSkill.value_below(d[:properties][:intrinsic])
                else
                    d[:properties][:adjectives] << GenericAspect.value_below(d[:properties][:intrinsic])
                end
                d[:properties].delete(:intrinsic)
            end

            # Copy over from the class info.
            d[:part_name] = object.class_info[:part_name]

            # FIXME - Add more things

            d
        end
    end

    class RoomDescriptor
        def self.describe(room, observer)
            friendly_name = room.name.gsub(/-\d+$/, '')
            {
                :is_type    => [:room, room.zone_type],
                :monicker   => room.zone_type,   # friendly_name.to_sym # TODO - change when name isn't just <keywords> <zone>
                :adjectives => room.keywords,
                :objects    => observer.perceivable_objects_of(room.objects - [observer]).collect { |o| BushidoObjectDescriptor.describe(o, observer) },
                :exits      => room.connected_directions
            }
        end
    end
end
