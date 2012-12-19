require 'raws/parser'

class BushidoObject
    def initialize(core, type, params={})
        Log.debug("Creating #{type}")
        Log.debug(["Creation params", params], 9)
        @core = core
        @type = type

        @properties = {}
        @extensions = []

        type_info = @core.db.info_for(type)

        type_info[:needs].each do |k|
            raise "Required argument #{k.inspect} missing during creation of #{type}" unless params.has_key?(k)
        end

        type_info[:default_values].each do |k,v|
            @properties[k] = v
        end

        type_info[:at_creation].each do |creation_proc|
            result = instance_eval(creation_proc)
            if Hash === result
                @properties.merge!(result)
            end
        end

        Log.debug("#{type} invoking #{type_info[:uses].size} extensions", 8)
        type_info[:uses].each do |mod|
            @extensions << mod
            extend mod
        end

        @extensions.each do |mod|
            if mod.respond_to?(:at_creation)
                mod.at_creation(self, params)
            end
        end

        type_info[:has].keys.each do |required_property|
            raise "Property #{required_property} has no value" unless @properties.has_key?(required_property)
        end

        self
    end

    def is_a?(type)
        current = [@type]
        until current == [:root]
            if current.include?(type)
                return true
            else
                current = current.collect { |t| @core.db.info_for(t)[:is_a] }.flatten.uniq
            end
        end
        return false
    end

    def method_missing(method_name, *args, &block)
        if @properties.has_key?(method_name)
            @properties[method_name]
        else
            raise "Property #{method_name} not found for #{@type}"
        end
    end

    def process_message(message)
        @extensions.each do |mod|
            break if mod.respond_to?(:at_message) && mod.at_message(self, message)
        end
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

    def create(core, type, params={})
        raise "#{type} not defined" unless @object_hash[type]
        raise "#{type} is not instantiable" if @object_hash[type][:abstract]
        BushidoObject.new(core, type, params)
    end
end

