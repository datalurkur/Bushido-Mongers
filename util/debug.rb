class Debug
    def self.deep_compare(a, b, context=[], ignored=[])
        failures = []
        tab = "\t" * context.size

        if a.class != b.class
            return [[context, a, b]]
        end

        case a
        when Array
            #Log.debug("#{tab}Comparing arrays #{a.size} | #{b.size}")
            return [[a.size, b.size]] unless a.size == b.size
            a.each_with_index do |x,i|
                sub_failures = deep_compare(x, b[i], context + [i], ignored)
                failures.concat(sub_failures)
            end
        when Hash
            #Log.debug("#{tab}Comparing hashes #{a.keys.size} | #{b.keys.size}")
            return [[a.keys.sort, b.keys.sort]] unless (a.keys - b.keys).empty?
            a.keys.each do |k|
                #Log.debug("#{tab}-#{k}")
                sub_failures = deep_compare(a[k], b[k], context + [k], ignored)
                failures.concat(sub_failures)
            end
        when Symbol,Fixnum,TrueClass,FalseClass,NilClass,String,Time,Set,Module,Float
            #Log.debug("#{tab}Comparing #{a.class.inspect}'s #{a} | #{b}")
            return [[context, a, b]] unless a == b
        when WordGroup,Lexicon::Lexeme
            return failures if ignored.include?(a.class)
            ignored.concat([a.class])
            Log.warning("Ignoring comparison of class #{a.class.inspect}")
        else
            Log.error("Unhandled type in deep compare: #{a.class.inspect}")
        end

        return failures
    end

    def self.deep_search_types(object, break_on=[], context=[])
        raise("Caught object type #{object.class} at #{context.inspect}") if break_on.include?(object.class)

        types = []
        case object
        when Array,Set
            types << object.class
            object.each_with_index do |sub_obj, i|
                types.concat(deep_search_types(sub_obj, break_on, context + [i]))
            end
        when Hash
            types << Hash
            object.each do |key, sub_obj|
                types.concat(deep_search_types(key, break_on, context + [:key]))
                types.concat(deep_search_types(sub_obj, break_on, context + [key]))
            end
        when Symbol,Fixnum,TrueClass,FalseClass,NilClass,Proc,String,Time,Float,Module
            types << object.class
        when WordGroup,Lexicon::Lexeme,Words::State
            types << object.class
        else
            raise "Unhandled type in deep search: #{object.class.inspect}"
        end

        return types.uniq
    end
end
