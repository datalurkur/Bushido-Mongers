require './knowledge/identities'
require './knowledge/quanta'
require './raws/db'

class ObjectKB < KB
    def initialize(db, use_identities = false)
    	@raws = db
        @groups_read = {}
        @use_identities = true
    end

    # Will add knowledge quanta, based on identities.
    def add_identities_for_type(raw_type)
        dbg_list = []
        GROUP_KNOWLEDGE.each do |k|
            raise "Not the right size: #{k}!" unless k.size == 3
            Log.debug("Analyzing #{k.inspect}", 6)
            k_type, connector, property = k
            if @raws.is_type?(raw_type, k_type)
                Log.debug("Type is #{k_type}", 6)
                if property.is_a?(Proc)
                    property = property.call(@raws, raw_type)
                end

                Array(property).each do |property|
                    dbg_list << _add(KBQuanta.new(:thing => raw_type, :connector => connector, :property => property))
                end
            end
        end
        Log.debug("Added #{dbg_list.size} quanta to #{self} for type #{raw_type}", 6)
    end

    # Lazily evaluated per-type.
    def all_quanta_for_type(raw_type)
    	known_bits = []
        # Blind cache hit retrieval. Re-evaluate sometimes?
        #if @groups_read[raw_type]
        #    return @groups_read[raw_type]
        #end

        add_identities_for_type(raw_type) if @use_identities

        # Check all parent types. Could use 'types known by kb' here for more dynamism.
        @raws.ancestry_of(raw_type).each do |parent|
            known_bits += @by_thing[parent] || []
        end

        # Check all child types if it's abstract. Could use 'types known by kb' here for more dynamism.
        if @raws.is_abstract?(raw_type)
            @raws.types_of(raw_type).each do |parent|
                known_bits += @by_thing[parent] || []
            end
        end

        Log.debug("known_bits for #{raw_type}: #{known_bits.inspect}", 6)
        @groups_read[raw_type] = known_bits
    	known_bits
    end

    def object_knowledge(object)
        # TODO
    end
end