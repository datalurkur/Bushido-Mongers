require 'raws/parser'

class ObjectDB
    class << self
        def get_object_hash_for(group)
            @object_groups ||= {}
            unless @object_groups[group]
                # TODO - Implement some caching scheme so that we don't have to parse the raws every time
                #      - Parse the raws and then re-save them as a parsed Marshalled hash with a checksum to validate whether the parsed data is current)

                @object_groups[group] = ObjectRawParser.load_objects(group)
            end
            @object_groups[group]
        end
    end

    def initialize(group)
        @object_hash = self.class.get_object_hash_for(group)
    end

    # Raw access
    def db
        @object_hash
    end
end

