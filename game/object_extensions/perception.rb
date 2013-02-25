require './util/exceptions'

module Perception
    class << self
        PERCEIVABLE_LOCATIONS = [:position, :grasped_objects, :stashed_objects, :worn_objects, :body]
    end

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
        when :grasped_objects
            return [] unless self.uses?(Equipment)
            # Objects held in hands, mouths, pincers, etc.
            self.all_grasped_objects.select do |object|
                object.matches(:type => type, :name => name)
            end
        when :stashed_objects
            return [] unless self.uses?(Equipment)
            # Search within the perceiver's backpacks, sacks, etc.
            self.containers_in_inventory.select do |cont|
                cont.internal_objects(true) do |object|
                    object.matches(:type => type, :name => name)
                end
            end
        when :worn_objects
            return [] unless self.uses?(Equipment)
            # Objects worn on the body.
            self.all_worn_objects.select do |object|
                object.matches(:type => type, :name => name)
            end
#        when :body
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

        # Explode inventory into appropriate categories.
        # FIXME - changes ordering...
        if locations.include?(:inventory)
            locations.delete(:inventory)
            locations += [:grasped_objects, :stashed_objects, :worn_objects]
        end

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
                return potentials.first
                # TODO - We should try re-searching here based on other descriptive information/heuristics.
            end
        end
    end
end
