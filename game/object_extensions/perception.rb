require './util/exceptions'

module Perception
    def perceivable_objects_of(list)
        list.select { |obj| can_perceive?(obj) }
    end

    # TODO - There should be some sort of cached perception check here,
    # which will be re-rolled given certain events.
    def can_perceive?(object)
        !(object.respond_to?(:skill) && object.has_skill?(:hide) && object.skill(:hide).get_property(:hidden))
    end

    def filter_objects(location, type=nil, name=nil)
        case location
        when :position
            # A player tied to a long pole can still grab apples
            perceivable_objects_of(self.absolute_position.objects).select do |object|
                object.matches(:type => type, :name => name)
            end
        when :inventory
            return [] unless self.uses?(Equipment)
            # First, look through the basic items.
            list = (self.all_grasped_objects + self.all_worn_objects).select do |object|
                object.matches(:type => type, :name => name)
            end
            # Then try searching in all the containers.
            # First, look through the basic items.
            list += self.containers_in_inventory.select do |cont|
                cont.internal_objects(true) do |object|
                    object.matches(:type => type, :name => name)
                end
            end
#            when :body
            # FIXME: Search through all resident corporeals' bodies.
#                []
        else
            Log.warning("#{location} lookups not implemented")
            []
        end
    end

    def find_object(type_class, object, locations)
        return object if (BushidoObject === object)
        object, adjectives = object if object.respond_to?(:size) && object.size == 2

#        Log.debug(["Searching!", type_class, object, locations])
#        Log.debug(["Adjectives!", adjectives]) if adjectives && !adjectives.empty?

        # Sort through the potentials and find out which ones match the query
        potentials = []
        locations.each do |location|
            results = filter_objects(location, type_class, object)
            potentials.concat(results)
            break unless potentials.empty?
        end

        case potentials.size
        when 0
            raise(NoMatchError, "No object #{object} found.")
        when 1
            return potentials.first
        else
            number = adjectives.map { |a| Words::Sentence::Adjective.ordinal?(a) }.flatten.first
            if number
                return potentials[number - 1]
            else
                # TODO - We should try re-searching here based on other descriptive information/heuristics.
                Log.debug(potentials)
                raise(AmbiguousMatchError, "Multiple #{type_class} objects found.")
            end
        end
    end
end
