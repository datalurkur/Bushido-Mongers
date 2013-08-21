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
        !(object.uses?(HasAspects) && object.get_aspect(:stealth).properties[:hidden])
    end

    def filter_objects(location, filters)
        case location
        when :position
            # A player tied to a long pole can still grab apples
            objects    = perceivable_objects_of(self.absolute_position.contents)
            containers = objects.select { |o| o.is_type?(:container) && o.open? }
            # perceivable objects in room + contents of perceivable open containers in room
            objects.select { |o| o.matches(filters) } +
            containers.map { |c| c.container_contents(:internal).select { |o| o.matches(filters) } }.flatten
        when :grasped, :worn
            return [] unless uses?(Composition) && uses?(Equipment)
            all_equipment(location).select do |object|
                object.matches(filters)
            end
        when :stashed
            return [] unless uses?(Composition) && uses?(Equipment)
            # Search within the perceiver's open backpacks, sacks, etc.
            matches = []
            containers_in_inventory.each { |c| c.open? }.each do |cont|
                submatches = cont.container_contents(:internal).select do |object|
                    object.matches(filters)
                end
                matches.concat(submatches)
            end
            matches.flatten
        when :external
            return [] unless uses?(Composition) && uses?(Corporeal)
            external_body_parts.select do |object|
                object.matches(filters)
            end
        when BushidoObject
            Log.debug("Finding #{filters[:name]}, #{filters[:type]} in #{location.monicker}", 6)
            if location.uses?(Composition)
                if location.uses?(Perception)
                    # TODO - This is weird. We shouldn't be using the external
                    # perception to search, but it doesn't matter yet.
                    # TODO - enable searching for internal parts if a body knowledge,
                    # skill-check passes, presumably using can_percieve?.
                    search_space = [:grasped, :stashed, :worn, :external]
                    result = location.find_object(filters[:type], filters[:name], [], search_space)
                    Log.debug(result)
                    return [result]
                elsif location.is_type?(:container)
                    if location.open?
                        location.container_contents(:internal) do |object|
                            object.matches(filters)
                        end
                    else
                        raise(FailedCommandError, "You can't search inside the #{location.monicker} because it's closed.")
                    end
                end
            elsif location.matches(filters)
                [location]
            end
        else
            Log.warning("#{location} lookups not implemented")
            []
        end
    end

    def find_all_objects(object_type, object_string, locations)
        matches = []
        # Explode inventory into appropriate categories.
        if i = locations.index(:inventory)
            locations.insert(i, :grasped, :stashed, :worn)
            locations.delete(:inventory)
        end
        Log.debug(["Searching #{locations.size} locations for #{object_type.inspect}/#{object_string.inspect}", locations])
        locations.each do |location|
            new_matches = filter_objects(location, {:type => object_type, :name => object_string})
            Log.debug("#{new_matches.size} matches found at #{location}")
            matches.concat(new_matches)
        end
        matches
    end

    def find_object(type_class, object, adjectives, locations)
        Log.warning("#{object.monicker} in find_object") if BushidoObject === object
#        return object if (BushidoObject === object)

        Log.debug(["Searching!", type_class, object, locations], 6)
        Log.debug(["Adjectives!", adjectives], 6) if adjectives && !adjectives.empty?

        # Explode inventory into appropriate categories.
        if i = locations.index(:inventory)
            locations.insert(i, :grasped, :stashed, :worn)
            locations.delete(:inventory)
        end

        # Sort through the potentials and find out which ones match the query
        potentials = []
        locations.each do |location|
            results = filter_objects(location, {:type => type_class, :name => object})
            potentials.concat(results)
            break unless potentials.empty?
        end

        Log.debug([potentials.map(&:monicker)], 6)

        case potentials.size
        when 0
            objects = find_all_objects(nil, object, locations)
            Log.debug([type_class, object, locations, objects])
            if objects && objects.is_a?(Array) && !objects.empty?
                raise(NoMatchError, "You can't do that to a #{objects.first.get_type}!")
            else
                raise(NoMatchError, "No object #{object} found.")
            end
        when 1
            return potentials.first
        else
            if adjectives
                number = adjectives.select { |a| Words::Adjective.ordinal?(a) }.first
                if number
                    return potentials[number - 1]
                else
                    Log.debug("#{self.monicker} assumes the first #{object}.")
                    return potentials.first
                    # TODO: Possibilities:
                    # * try re-searching here based on other descriptive information/heuristics.
                    # * Throw AmbiguousCommandError and request more info
                end
            else
                return potentials.first
            end
        end
    end
end
