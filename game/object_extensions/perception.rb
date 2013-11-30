require './util/exceptions'

module Perception
    PERCEIVABLE_LOCATIONS = [:grasped, :stashed, :worn, :position, :external]

    def perceivable_objects_of(list)
        list.select { |obj| can_perceive?(obj) }
    end

    # Explode inventory into appropriate categories.
    def explode_locations(locations)
        locations = Array(locations)
        {   :all       => PERCEIVABLE_LOCATIONS,
            :inventory => [:grasped, :stashed, :worn]
        }.each do |orig, replacement_list|
            if i = locations.index(orig)
                locations.insert(i, *replacement_list)
                locations.delete(orig)
            end
        end
        locations
    end

    # TODO - There should be some sort of cached perception check here,
    # which will be re-rolled given certain events.
    def can_perceive?(object)
        !(object.uses?(Aspectual) && object.get_aspect(:stealth).properties[:hidden])
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
            Log.debug("Searching in #{location.monicker}", 6)
            if location.uses?(Composition)
                if location.container?
                    if location.open?
                        location.container_contents(:internal)
                    else
                        raise(FailedCommandError, "You can't search inside the #{location.monicker} because it's closed.")
                    end
                elsif location.uses?(Perception)
                    # TODO - enable searching for internal parts if a body knowledge,
                    # skill-check passes, presumably using can_percieve?.
                    raise(StandardError, "Searching in non-room non-container BushidoObject?")
                end
            else
                [location]
            end
        else
            Log.warning("#{location} lookups not implemented")
            []
        end
    end

    # Return all the objects matching the filter at locations.
    # Note that adjectives in the filter are currently a placeholder.
    def filter_objects(locations, filter)
        locations = explode_locations(locations)

        Log.debug("#{self.monicker} is finding things" +
                  (filter[:name] ? " named #{filter[:name].inspect}"   : '') +
                  (filter[:type] ? " of type #{filter[:type].inspect}" : '') +
                  (filter[:uses] ? " that use #{filter[:uses].inspect}"   : '') +
                  (filter[:adjectives] ? " with adjectives #{filter[:adjectives].inspect}" : '') +
                  (locations     ? " in #{locations.inspect}"          : ''),
                 5)

        matches = locations.inject([]) do |matches, location|
            new_matches = objects_in_location(location).select { |object| object.matches(filter) }
            Log.debug("#{new_matches.size} matches found at #{location}", 6)
            matches + new_matches
        end
    end

    def filter_for(object_type = nil, object_string = nil, adjectives = [], uses = nil)
       {:type => object_type, :name => object_string, :adjectives => adjectives, :uses => uses}
    end

    # Note that this method throws exceptions when items aren't found,
    # which may not be what you want. Consider using filter_objects paired with
    # filter_for or Commands.filter_for_key.
    def find_object(locations = [:all], filter = {})
        locations = explode_locations(locations)

        # Sort through the potentials and find out which ones match the query
        potentials = filter_objects(locations, filter)

        Log.debug([potentials.map(&:monicker)], 6)

        case potentials.size
        when 0
            raise(NoMatchError, "No such #{filter[:type] || filter[:name]} found.")
        when 1
            return potentials.first
        else
            if filter[:adjectives] && (number = filter[:adjectives].map { |a| Words::Adjective.ordinal?(a) }.compact.first)
                Log.debug([number, number.class])
                Log.debug("Found adjective for #{number - 1}")
                raise(NoMatchError, "Not that many #{filter[:type]}s!") if number > potentials.size
                return potentials[number - 1]
            else
                Log.debug("#{self.monicker} assumes the first #{filter[:type]}.")
                return potentials.first
                # TODO: Possibilities:
                # * try re-searching here based on other descriptive information/heuristics.
                # * Throw AmbiguousCommandError and request more info
            end
        end
    end
end
