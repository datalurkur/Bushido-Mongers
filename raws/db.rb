require 'raws/parser'
require 'raws/bushido_object'
require 'util/timer'

class ObjectDB
    class << self
        def get(group)
            @object_groups ||= {}
            unless @object_groups[group]
                # TODO - Implement some caching scheme so that we don't have to parse the raws every time
                #      - Parse the raws and then re-save them as a parsed Marshalled hash with a checksum to validate whether the parsed data is current)

                @object_groups[group] = ObjectRawParser.fetch(group)
                verify_class_values(@object_groups[group])
            end
            @object_groups[group]
        end

        def verify_class_values(db)
            db.each_type do |type|
                next if db[type][:abstract]
                db[type][:has].each do |k,v|
                    if v[:class_only] && !db[type][:class_values].has_key?(k)
                        raise "Class value #{k.inspect} missing from #{type.inspect}"
                    end
                end
            end
        end
    end

    def [](type)
        @db[type]
    end

    def each_type(&block)
        return unless block_given?
        @db.keys.each do |type|
            block.call(type)
        end
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

    def random(type)
        types_of(type).rand
    end

    def create(core, type, params={})
        raise "#{type.inspect} not defined" unless @db[type]
        raise "#{type.inspect} is not instantiable" if @db[type][:abstract]
        BushidoObject.new(core, type, params)
    end

    def get_binding
        binding()
    end

    def find_subtypes(parent_types, criteria={}, instantiable_only=false)
        Log.debug(["Finding #{parent_types.inspect} that meet criteria", criteria])
        check = criteria.reject { |k,v| k == :inclusive }
        Log.debug("find_subtypes")
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
        raise "Incorrect database format"  unless Hash === db
        @db   = db
        @hash = hash
    end
end

