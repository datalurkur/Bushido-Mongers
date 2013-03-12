require './util/exceptions'

module Perception
    class << self
        PERCEIVABLE_LOCATIONS = [:position, :grasped, :stashed, :worn, :body]
    end

    def perceivable_objects_of(list)
        list.select { |obj| can_perceive?(obj) }
    end

    # TODO - There should be some sort of cached perception check here,
    # which will be re-rolled given certain events.
    def can_perceive?(object)
        !(object.respond_to?(:skill) && object.has_skill?(:hide) && object.skill(:hide).properties[:hidden])
    end

    def filter_objects(location, type=nil, name=nil)
        case location
        when :position
            # A player tied to a long pole can still grab apples
            perceivable_objects_of(self.absolute_position.objects).select do |object|
                object.matches(:type => type, :name => name)
            end
        when :grasped, :worn
            return [] unless Composition === self && Inventory === self
            all_equipment(location).select do |object|
                object.matches(:type => type, :name => name)
            end
        when :stashed
            return [] unless Composition === self && Inventory === self
            # Search within the perceiver's backpacks, sacks, etc.
            containers_in_inventory.select do |cont|
                cont.container_contents do |object|
                    object.matches(:type => type, :name => name)
                end
            end
        when :external
            return [] unless Composition === self && Corporeal === self
            external_body_parts.select do |object|
                object.matches(:type => type, :name => name)
            end
        when BushidoObject
            Log.debug("Finding #{name}, #{type} in #{location.monicker}", 6)
            if location.uses?(Composition)
                if location.uses?(Perception)
                    # TODO - This is weird. We shouldn't be using the external
                    # perception to search, but it doesn't matter yet.
                    # TODO - enable searching for internal parts if a body knowledge,
                    # skill-check passes, presumably using can_percieve?.
                    search_space = [:grasped, :stashed, :worn, :external]
                    result = location.find_object(type, name, search_space)
                    Log.debug(result)
                    return [result]
#                    [location.find_object(type, name, search_space)]
                elsif location.container?
                    if location.open?
                        location.container_contents do |object|
                            object.matches(:type => type, :name => name)
                        end
                    else
                        raise(FailedCommandError, "You can't search inside the #{location.monicker} because it's closed.")
                    end
                end
            elsif location.matches(:type => type, :name => name)
                [location]
            end
        else
            Log.warning("#{location} lookups not implemented")
            []
        end
    end

    def find_object(type_class, object, locations)
        Log.warning("#{object.monicker} in find_object") if BushidoObject === object
#        return object if (BushidoObject === object)
        object, adjectives = object if object.respond_to?(:size) && object.size == 2

        Log.debug(["Searching!", type_class, object, locations], 6)
        Log.debug(["Adjectives!", adjectives], 6) if adjectives && !adjectives.empty?

        # Explode inventory into appropriate categories.
        # FIXME - changes ordering.
        if locations.include?(:inventory)
            locations.delete(:inventory)
            locations += [:grasped, :stashed, :worn]
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
            if adjectives
                number = adjectives.map { |a| Words::Sentence::Adjective.ordinal?(a) }.flatten.first
                if number
                    return potentials[number - 1]
                else
                    return potentials.first
                    # TODO - We should try re-searching here based on other descriptive information/heuristics.
                end
            else
                return potentials.first
            end
        end
    end
end
