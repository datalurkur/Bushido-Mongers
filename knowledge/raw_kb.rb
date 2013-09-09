require './knowledge/identities'
require './knowledge/quanta'
require './raws/db'

class ObjectKB < KB
    attr_reader :use_identities
    def initialize(db, use_identities = false)
    	@raws = db
        @groups_read = {}
        @use_identities = use_identities
    end

    # Will add knowledge quanta, based on identities.
    def read_identities_for_type(raw_type)
        # Blind cache hit retrieval. Re-evaluate sometimes?
        if @groups_read[raw_type]
            return @groups_read[raw_type]
        end

        known_bits = []
        GROUP_KNOWLEDGE.each do |k|
            raise "Not the right size: #{k}!" unless k.size == 3
            Log.debug("Analyzing #{k.inspect}", 6)
            thing, connector, property = k
            if @raws.is_type?(raw_type, thing)
                Log.debug("Type is #{thing}", 6)
                if property.is_a?(Proc)
                    property = property.call(@raws, raw_type)
                end

                Array(property).each do |property|
                    known_bits << _add(KBQuanta.new(:thing => raw_type, :connector => connector, :property => property))
                end
            end
        end
        Log.debug("Found #{known_bits.size} quanta to #{self} for #{raw_type}", 6)
        @groups_read[raw_type] = known_bits
    end

    # Lazily evaluated per-type.
    def all_quanta_for_type(raw_type)
        _init_indices
        read_identities_for_type(raw_type) if @use_identities

        known_bits = []
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
    	known_bits
    end

    def read_identities_for_object(object)
        known_bits = []
        IDENTITIES.each do |k|
            raise "Not the right size: #{k}!" unless [3, 4].include?(k.size)
            Log.debug("Analyzing #{k.inspect}", 6)
            thing, connector, property, value = k
            value = value.call(@raws, object) if value && value.is_a?(Proc)

            Array(property).each do |property|
                known_bits << _add(KBQuanta.new(:thing => object, :connector => connector, :property => property, :value => value))
            end
        end
        known_bits
    end

    # N.B. Eventually we want quanta of individuals to supercede their group quanta.
    def all_quanta_for_object(object)
        known_bits  = all_quanta_for_type(object.get_type)
        known_bits += read_identities_for_object(object) if @use_identities
        known_bits
    end

    # def add_identities(object); end

    def all_quanta_for(object)
        if object.is_a?(BushidoObject)
            all_quanta_for_object(object)
        elsif @raws.has_type?(object)
            all_quanta_for_type(object)
        elsif Symbol === object
            Log.warning("Quanta for bareword Symbol #{object.inspect} not supported!")
            read_identities_for_object(object) if @use_identities
            # add_identities(object)
        end
    end
end