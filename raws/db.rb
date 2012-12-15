require 'raws/parser'

class BushidoObject
    def initialize(type, db, args={})
        Log.debug("Creating #{type} with args #{args.inspect}")
        @db   = db
        @type = type

        @properties = {}

        type_info = @db.info_for(type)

        type_info[:needs].each do |k|
            raise "Required argument #{k} missing during creation of #{type}" unless args.has_key?(k)
        end

        type_info[:default_values].each do |k,v|
            @properties[k] = v
        end

        type_info[:at_creation].each do |creation_proc|
            result = instance_exec(args, &creation_proc)
            @properties.merge!(result)
        end

        type_info[:has].keys.each do |required_property|
            raise "Property #{required_property} has no value" unless @properties.has_key?(required_property)
        end

        self
    end

    def is_a?(type)
        current = @type
        while current != :root
            if type == current
                return true
            else
                current = @db.info_for(current)[:is_a]
            end
        end
        return false
    end

    def method_missing(method_name, *args, &block)
        @properties.has_key?(method_name) ? @properties[method_name] : super(method_name, *args, &block)
    end
end

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

    def info_for(type)
        raise "#{type.inspect} not defined" unless @object_hash[type]
        @object_hash[type]
    end

    def types_of(type)
        raise "#{type} not defined" unless @object_hash[type]
        if @object_hash[type][:abstract]
            @object_hash[type][:subtypes].collect { |subtype| types_of(subtype) }.flatten
        else
            [type]
        end
    end

    # Given a list of abstract and concrete types, returns all concrete types that match any input types.
    def expand_types(list)
        list.inject([]) do |arr, type|
            arr + types_of(type)
        end.flatten.uniq
    end

    def random(type)
        types_of(type).rand
    end

    def create(type, args={})
        raise "#{type} not defined" unless @object_hash[type]
        raise "#{type} is not instantiable" if @object_hash[type][:abstract]
        BushidoObject.new(type, self, args)
    end
end

