require './util/exceptions'

module Perception
    PERCEIVABLE_LOCATIONS = [:grasped, :stashed, :worn, :position, :external]

    def perceivable_objects_of(list)
        list.select { |obj| can_perceive?(obj) }
    end

    # Explode inventory into appropriate categories.
    def explode_locations(locations)
        locations = Array(locations)
        if i = locations.index(:all)
            locations.insert(i, *PERCEIVABLE_LOCATIONS)
            locations.delete(:all)
        end
        if i = locations.index(:inventory)
            locations.insert(i, :grasped, :stashed, :worn)
            locations.delete(:inventory)
        end
        locations
    end

    # TODO - There should be some sort of cached perception check here,
    # which will be re-rolled given certain events.
    def can_perceive?(object)
        !(object.uses?(HasAspects) && object.get_aspect(:stealth).properties[:hidden])
    end

    def objects_in_location(location)
        case location
        when :position
            # A player tied to a long pole can still grab apples
            objects    = perceivable_objects_of(self.absolute_position.get_contents(:internal))
            containers = objects.select { |o| o.is_type?(:container) && o.open? }
            # perceivable objects in room + (non-recursive) contents of perceivable open containers in room
            contained_objects = containers.map   { |c| c.get_contents(:internal) }.flatten
            (objects + contained_objects)
        when :grasped, :worn
            return [] unless uses?(Composition) && uses?(Equipment)
            all_equipment(location)
        when :stashed
            return [] unless uses?(Composition) && uses?(Equipment)
            # Search within the perceiver's open backpacks, sacks, etc.
            matches = []
            containers_in_inventory.each { |c| c.open? }.each do |container|
                matches += container.select_objects(:internal, false)
            end
            matches.flatten
        when :external
            return [] unless uses?(Composition) && uses?(Corporeal)
            external_body_parts
        when BushidoObject
            Log.debug("Finding #{filters[:name]}, #{filters[:type]} in #{location.monicker}", 6)
            if location.uses?(Composition)
                if location.uses?(Perception)
                    # TODO - This is weird. We shouldn't be using the external
                    # perception to search, but it doesn't matter yet.
                    # TODO - enable searching for internal parts if a body knowledge,
                    # skill-check passes, presumably using can_percieve?.
                    raise StandardError, "Searching in non-room non-container BushidoObject?"
                    #search_space = [:grasped, :stashed, :worn, :external]
                    #result = location.find_object(filters[:type], filters[:name], [], search_space)
                    #Log.debug(result)
                    #return [result]
                elsif location.is_type?(:container)
                    if location.open?
                        location.container_contents(:internal)
                    else
                        raise(FailedCommandError, "You can't search inside the #{location.monicker} because it's closed.")
                    end
                end
            else
                [location]
            end
        else
            Log.warning("#{location} lookups not implemented")
            []
        end
    end

    def filter_objects(location, filters)
        objects_in_location(location).select { |object| object.matches(filters) }
    end

    def find_all_objects(object_type, object_string, locations)
        explode_locations(locations)
        Log.debug(["Searching #{locations.size} locations for #{object_type.inspect}/#{object_string.inspect}", locations])

        matches = locations.inject([]) do |matches, location|
            new_matches = filter_objects(location, {:type => object_type, :name => object_string})
            Log.debug("#{new_matches.size} matches found at #{location}")
            matches + new_matches
        end
        matches
    end

    def find_object(type_class, object, adjectives, locations)
        Log.warning("#{object.monicker} in find_object") if BushidoObject === object

        explode_locations(locations)

        Log.debug(["Searching!", type_class, object, locations], 6)
        Log.debug(["Adjectives!", adjectives], 6) if adjectives && !adjectives.empty?

        # Sort through the potentials and find out which ones match the query
        potentials = locations.inject([]) do |potentials, location|
            potentials + filter_objects(location, {:type => type_class, :name => object})
        end

        Log.debug([potentials.map(&:monicker)], 6)

        case potentials.size
        when 0
            objects = find_all_objects(nil, object, locations)
            Log.debug([type_class, object, locations, objects])
            if objects && objects.is_a?(Array) && !objects.empty?
                raise(NoMatchError, "You can't do that to a #{objects.first.get_type}!")
            else
                raise(NoMatchError, "No #{object} found.")
            end
        when 1
            return potentials.first
        else
            if adjectives
                number = adjectives.map { |a| Words::Adjective.ordinal?(a) }.compact.first
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
