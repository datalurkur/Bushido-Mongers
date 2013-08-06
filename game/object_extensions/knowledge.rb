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
    Internally, there are concepts of inclusive and exclusive knowledge.  Inclusive knowledge means you
    know everything about a subject (or sub-subject) all the time, with no exceptions.  You've learned
    it, any sub-queries are handled as such.  Exclusive knowledge is used for knowledge gained on-the-fly,
    such as the location of a person.  Obviously, you can never know the location of a person all the time
    unless you happen to be omniscient / omnipresent / etc (which can be reflected in inclusive knowledge
    if need be).
    
=end

require './knowledge/kb'

module Knowledge
    class << self
        def pack(instance)
            {:knowledge => instance.knowledge}
        end

        def unpack(core, instance, raw_data)
            instance.unpack_knowledge(raw_data[:knowledge])
        end

        def at_creation(instance, params)
            instance.add_basic_knowledge(params)
        end

        def categories; [:location, :details, :info]; end
    end

    def knowledge() @knowledge; end

    def add_basic_knowledge(params)
        @knowledge = ObjectKB.new(@core.db)
        # TODO: Fill out knowledge based on :know identities.
    end

    def unpack_knowledge(knowledge)
        @knowledge = knowledge
    end

    def add_knowledge(thing, connector, property)
        @knowledge.add_knowledge(:thing => thing, :connector => connector, :property => property)
    end

    def remove_knowledge(thing, connector, property)
        # TODO
    end

    def get_knowledge(thing, connector=nil, property=nil)
        if knows_of_class?(thing)
            get_knowledge_of_group(thing, connector, property)
        else
            get_specific_knowledge(thing, connector, property)
        end
    end

    def known_types(type)
        (get_knowledge_of_group(type) + kb.type_knowledge(type)).uniq.map { |q| q.connector == :is }
    end

    # Eventually we want to check the object's knowledge here, but this will suffice for now.
    def knows_of_class?(raw_type)
        @core.db.has_type?(raw_type)
    end

    def get_all_knowledge_of_group(raw_type)
        raise "#{raw_type} is not an object type!" unless @core.db.has_type?(raw_type)
        # Check basic raw knowledge first, then look in memory (local knowledge).
        (@core.kb.all_quanta_for_type(raw_type) + @knowledge.all_quanta_for_type(raw_type)).uniq
    end

    def get_knowledge_of_group(raw_type, connector=nil, property=nil)
        raise "#{raw_type} is not an object type!" unless @core.db.has_type?(raw_type)
        all = get_all_knowledge_of_group(raw_type)

        return all.select do |q|
            (connector.nil? || q.connector == connector) &&
            (property.nil?  || q.property == property)
        end || []
    end

    def get_specific_knowledge(thing, connector, property)
        Log.debug([thing, connector, property])
        @knowledge.get_thing_knowledge(:thing => thing, :connector => connector, :property => property)
    end
end
