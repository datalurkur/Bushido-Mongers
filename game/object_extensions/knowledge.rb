=begin
    =====================
    INTERFACE
    =====================
    Knowledge stores things a player or NPC "knows" about the world and the things in it.

    Basic knowledge categories:
        -Spatial/Temporal (where something is, ie Kenji is in the Old Sewer)
        -Object Details (information about a particular object, ie Kenji has many scars)
        -Object Information (information about an abstact object, ie humans have 2 legs)

    A query is composed of a knowledge category and a query path
        Example 1: I want to know where Kenji is
            [:location, "Kenji"] => <Kenji's last known location>
        Example 2: I want to know about Kenji
            [:details, "Kenji"] => <General details>
        Example 3: I want to know about Kenji's scars
            [:details, "Kenji", :wounds] => <Wound details>
        Example 4: I want to know how to make a sword
            [:info, :sword, :recipes] => <List of recipes>

    =====================
    IMPLEMENTATION
    =====================
    Internally, there are concepts of inclusive and exclusive knowledge.  Inclusive knowledge means you know everything about a subject (or sub-subject) all the time, with no exceptions.  You've learned it, any sub-queries are handled as such.  Exclusive knowledge is used for knowledge gained on-the-fly, such as the location of a person.  Obviously, you can never know the location of a person all the time unless you happen to be omniscient / omnipresent / etc (which can be reflected in inclusive knowledge if need be).
    
=end
module Knowledge
    class << self
        def pack(instance)
            {:inclusive => instance.inclusive_knowledge, :exclusive => instance.exclusive_knowledge}
        end

        def unpack(core, instance, raw_data)
            instance.unpack_knowledge_base(raw_data[:inclusive], raw_data[:exclusive])
        end

        def categories; [:location, :details, :info]; end
    end

    def inclusive_knowledge; @inclusive_knowledge ||= {}; end
    def exclusive_knowledge; @exclusive_knowledge ||= {}; end
    def unpack_knowledge_base(inclusive, exclusive)
        @inclusive_knowledge = inclusive
        @exclusive_knowledge = exclusive
    end

    def add_knowledge_of(query_path, inclusive=false, data=nil)
        raise(ArgumentError, "Inclusive knowledge cannot have associated data") if inclusive && data
        raise(ArgumentError, ":data is a reserved keyword") if query_path.include?(:data)
        raise(ArgumentError, "Query path must begin with one of the following: #{Knowledge.categories.inspect}") unless Knowledge.categories.include?(query_path[0])

        Log.debug("Adding #{inclusive ? "inclusive" : "exclusive"} knowledge of #{query_path.inspect} to #{monicker} #{data ? "(with data)" : ""}")

        current = inclusive ? inclusive_knowledge : exclusive_knowledge
        path    = query_path.dup
        while (next_key = path.shift)
            return if current.has_key?(next_key) && inclusive
            current[next_key] ||= {}
            current = current[next_key]
        end
        (current[:data] = data) if data
        Log.debug("Knowledge added")
    end

    def get_knowledge_of(query_path)
        raise(ArgumentError, ":data is a reserved keyword") if query_path.include?(:data)
        raise(ArgumentError, "Query path must begin with one of the following: #{Knowledge.categories.inspect}") unless Knowledge.categories.include?(query_path[0])

        # Try inclusive knowledge first
        current = inclusive_knowledge
        path    = query_path.dup
        while (next_key = path.shift)
            if current[next_key]
                return fetch_data_for(query_path)
            else
                break
            end
        end

        # Fall back to exclusive knowledge, most commonly
        current = exclusive_knowledge
        path    = query_path.dup
        while (next_key = path.shift)
            if current[next_key]
                current = current[next_key]
            else
                return nil
            end
        end
        # Barring actual factually stored data, seek out the requisite data and return it
        return current[:data] || fetch_data_for(query_path)
    end

    private
    def fetch_data_for(query_path)
        category, path = query_path[0], query_path[1..-1]
        case category
        when :location
            if path.size > 1
                Log.warning("Location paths are intended to be of singular depth (either a name or a type)")
                Log.warning("#{path[1..-1].inspect} will be discarded")
            end
            @core.populations.locate(path[0])
        when :details
            raise(NotImplementedError, "We are yet unable to detail things")
        when :info
            basic_info = @core.db.info_for(path.shift)
            info = basic_info
            while (next_key = path.shift)
                raise(MissingProperty, "Info #{next_key} missing from #{query_path}") unless info.has_key?(next_key)
                info = info[next_key]
            end
            return info
        else
            raise(NotImplementedError, "Unrecognized query type #{category}")
        end
    end
end
