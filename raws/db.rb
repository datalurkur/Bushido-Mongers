require './raws/parser'
require './raws/bushido_object'
require './util/timer'
require './util/exceptions'

class ObjectDB
    class << self
        def get(group)
            @object_groups ||= {}
            unless @object_groups[group]
                # TODO - Implement some caching scheme so that we don't have to parse the raws every time
                #      - Parse the raws and then re-save them as a parsed Marshalled hash with a checksum to validate whether the parsed data is current)

                time_block("Raws fetched") do
                    @object_groups[group] = ObjectRawParser.fetch(group)
                    verify_class_values(@object_groups[group])
                end
            end
            @object_groups[group]
        end

        def verify_class_values(db)
            db.each_type do |type|
                next if db[type][:abstract]
                db[type][:has].each do |k,v|
                    if v[:class_only]
                        has_value = v[:multiple] ? !db[type][:class_values].empty? : db[type][:class_values].has_key?(k)
                        raise(StandardError, "Class value #{k.inspect} missing from #{type.inspect}.") unless has_value || v[:optional]
                    end
                end
            end
        end
    end

    def [](type)
        @db[type]
    end

    def has_type?(name)
        @db.has_key?(name)
    end

    def each_type(instantiable_only=false, &block)
        return unless block_given?
        @db.keys.each do |type|
            next if instantiable_only && raw_info_for(type)[:abstract]
            block.call(type)
        end
    end

    def raw_info_for(type)
        raise(UnknownType, "#{type.inspect} not defined as db type") unless @db.has_key?(type)
        @db[type]
    end

    def info_for(type, datapoint=nil)
        type_hash = raw_info_for(type)
        return type_hash[:class_values] if datapoint.nil?

        ret = type_hash[:class_values][datapoint]
        Marshal.load(Marshal.dump(ret))
    end

    def minimum_depth_of(type)
        info = raw_info_for(type)
        unless info[:abstract]
            return 0
        else
            return info[:subtypes].collect { |s| minimum_depth_of(s) }.min
        end
    end

    private
    def set_info(type, datapoint, value)
        type_hash = raw_info_for(type)
        type_hash[:class_values][datapoint] = value
    end

    # Will not destroy pre-existing data.
    def modify_info(type, datapoint, init_value = nil)
        type_hash = raw_info_for(type)

        if type_hash[:class_values][datapoint].nil?
            type_hash[:class_values][datapoint] = init_value
        end
        type_hash[:class_values][datapoint]
    end

    public
    def types_of(types, instantiable_only=true)
        list = (Array === types) ? types : [types]
        list.compact.inject([]) do |arr, type|
            arr + types_of_singular(type, instantiable_only)
        end.flatten.uniq
    end

    def types_of_singular(type, instantiable_only)
        info = raw_info_for(type)
        if info[:abstract]
            subtypes = info[:subtypes].collect do |subtype|
                types_of_singular(subtype, instantiable_only)
            end.flatten.compact
            instantiable_only ? subtypes : [type] + subtypes
        else
            [type]
        end
    end

    def is_abstract?(type)
        raw_info_for(type)[:abstract]
    end

    def is_type?(type, parent_type)
        Log.debug("Is #{type.inspect} a #{parent_type.inspect}? (from #{caller[0]})", 8)
        return true  if parent_type == :root
        return false if        type == :root
        current = Array(type)
        until current.empty?
            if current.include?(parent_type)
                Log.debug("Yes!", 8)
                return true
            else
                current = current.collect { |t| raw_info_for(t)[:is_type] }.flatten.uniq
            end
            current.reject! { |t| t == :root }
        end
        Log.debug("No!", 8)
        return false
    end

    def ancestry_of(type)
        types   = []
        current = [type]
        until current.empty?
            types.concat(current)
            current = current.collect { |t| raw_info_for(t)[:is_type] }.flatten.uniq
            current.reject! { |t| t == :root }
        end
        types
    end

    def random(type)
        types_of(type).rand
    end

    def create(core, type, uid, params)
        raise(UnknownType, "#{type.inspect} not defined as db type.") unless @db[type]
        if @db[type][:abstract]
            if params[:randomize]
                type = types_of(type).rand
            else
                raise(ArgumentError, "#{type.inspect} is not instantiable.")
            end
        end

        # When no longer in debug mode, go back to using BushidoObject
        #BushidoObject.create(core, type, params)
        SafeBushidoObject.create(core, type, uid, params)
    end

    def get_binding
        binding()
    end

    def find_subtypes(parent_types, criteria={}, instantiable_only=false)
        Log.debug(["Finding #{parent_types.inspect} that meet criteria", criteria], 9)
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

    metered :propagate_recursive, :find_subtypes, :create, :types_of

    attr_reader :hash

    private
    # We don't want users calling this, since the static class methods do the actual database population
    def initialize(db, hash)
        raise(ArgumentError, "Incorrect database format") unless Hash === db
        @db   = db
        @hash = hash
    end

    def duplicate_object(original_type, new_type, new_params={})
        new_object = Marshal.load(Marshal.dump(@db[original_type]))
        new_params.each do |k,v|
            case v
            when Array
                new_object[k].concat(v)
            when Hash
                new_object[k].merge!(v)
            else
                raise(NotImplementedError, "DB doesn't know how to merge attributes of type #{v.class}.")
            end
        end
        new_object[:is_type].each do |parent_type|
            @db[parent_type][:subtypes] << new_type
        end
        @db[new_type] = new_object
    end
end

