require 'raws/parser'

class BushidoObject
    def initialize(core, type, params={})
        Log.debug("Creating #{type}")
        Log.debug(["Creation params", params], 8)
        @core = core
        @type = type

        @properties = {}
        @extensions = []

        type_info = @core.db.raw_info_for(type)
        Log.debug(["Type info", type_info], 8)

        type_info[:needs].each do |k|
            raise "Required argument #{k.inspect} missing during creation of #{type}" unless params.has_key?(k)
        end

        type_info[:class_values].each do |k,v|
            unless type_info[:has].has_key?(k) && type_info[:has][k][:class_only]
                (@properties[k] = v) 
            end
        end

        type_info[:at_creation].each do |creation_proc|
            result = eval(creation_proc, nil, __FILE__, __LINE__)
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

        type_info[:has].keys.each do |property|
            next if type_info[:has][property][:class_only]
            if type_info[:has][property][:multiple]
                if @properties[property].empty? && !type_info[:has][property][:optional]
                    raise "Property #{property} has no values"
                end
            else
                unless @properties.has_key?(property)
                    if type_info[:has][property][:optional]
                        @properties[property] = nil
                    else
                        raise "Property #{property} has no value"
                    end
                end
            end
        end

        self
    end

    def is_a?(type)
        (return false) if (@type == :root)
        current = [@type]
        until current.empty?
            if current.include?(type)
                return true
            else
                current = current.collect { |t| @core.db.raw_info_for(t)[:is_a] }.flatten.uniq
            end
            current.reject! { |t| t == :root }
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
        def get(group)
            @object_groups ||= {}
            unless @object_groups[group]
                # TODO - Implement some caching scheme so that we don't have to parse the raws every time
                #      - Parse the raws and then re-save them as a parsed Marshalled hash with a checksum to validate whether the parsed data is current)

                @object_groups[group] = ObjectRawParser.load_objects(group)
            end
            @object_groups[group]
        end
    end

    def initialize(db)
        raise "Incorrect database format"  unless Hash === db
        @db = db
    end

    def [](type)
        @db[type]
    end

    def raw_info_for(type)
        raise "#{type.inspect} not defined" unless @db[type]
        @db[type]
    end

    def info_for(type, datapoint, initialize_to=nil)
        type_hash = raw_info_for(type)
        unless type_hash[:class_values].has_key?(datapoint) || initialize_to.nil?
            type_hash[:class_values][datapoint] = initialize_to
        end
        type_hash[:class_values][datapoint]
    end

    def types_of(types, instantiable_only=true)
        list = (Array === types) ? types : [types]
        list.compact.inject([]) do |arr, type|
            arr + types_of_singular(type, instantiable_only)
        end.flatten.uniq
    end

    def types_of_singular(type, instantiable_only)
        info = raw_info_for(type)
        if info[:abstract]
            subtypes = info[:subtypes].collect { |subtype| types_of(subtype) }.flatten.compact
            instantiable_only ? subtypes : [type] + subtypes
        else
            [type]
        end
    end

    def is_abstract?(type)
        raw_info_for(type)[:abstract]
    end

    def random(type)
        types_of(type).rand
    end

    def create(core, type, params={})
        raise "#{type} not defined" unless @db[type]
        raise "#{type} is not instantiable" if @db[type][:abstract]
        BushidoObject.new(core, type, params)
    end

    def get_binding
        binding()
    end

    def find_subtypes(parent_types, criteria={}, instantiable_only=false)
        Log.debug(["Finding #{parent_types.inspect} that meet criteria", criteria])
        check = criteria.reject { |k,v| k == :inclusive }
        types_of(parent_types, instantiable_only).select do |subtype|
            Log.debug("Checking #{subtype} for adherence to criteria", 9)
            keep = true
            check.each do |k,v|
                comp = info_for(subtype, k)
                case comp
                when Array
                    case v
                    when Array
                        next if (inclusive ? !(v & comp).empty? : v == comp)
                    else
                        next if comp.include?(v)
                    end
                else
                    case v
                    when Array
                        next if (inclusive ? v.include?(comp) : v == comp)
                    else
                        next if(v === comp)
                    end
                end

                Log.debug("Fails check for #{k} : #{v.inspect} - #{info_for(subtype, k).inspect}", 9)
                keep = false
                break
            end
            keep
        end
    end

    def propagate_recursive(type, instantiable_only=false, &block)
        types_of(type, instantiable_only).each do |subtype|
            block.call(subtype)
        end
    end
end

