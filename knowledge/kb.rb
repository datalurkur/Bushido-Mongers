# This KnowledgeBase is somewhat informed by the Nyaya logic school of Hindu philosophy.
# http://en.wikipedia.org/wiki/Nyaya#Epistemology

EPISTEMIC_CATEGORIES = # padarthas
[
    :valid,           # pramāṇa (valid means of knowledge)
    :object_of_valid, # prameya (objects of valid knowledge)
    :doubt,           # saṁśaya (doubt)
    :aim,             # prayojana (aim)
    :example,         # dṛṣṭānta (example)
    :conclusion,      # siddhānta (conclusion)
    :waypoint,        # avayava (members of syllogism)
    :hypothetical,    # tarka (hypothetical reasoning)
    :settlement,      # nirṇaya (settlement, finalization)
    :discussion,      # vāda (discussion)
    :wrangling,       # jalpa (wrangling)
    :cavilling,       # vitaṇḍā (cavilling, frivolous discussion)
    :fallacy,         # hetvābhāsa (fallacy)
    :quibbling,       # chala (quibbling)
    :refutation,      # jāti (sophisticated refutation)
    :defeat           # nigrahasthāna (point of defeat)
]

GENERALITY =
[
    :general,
    :specific
]

EPISTEMIC_SOURCES =
[
    :perception,
    :extraordinary_perception,
    :inference,
    :comparison,
    :testimony
]

PERCEPTIONS =
[
    :see,
    :hear,
    :taste,
    :touch,
    :smell,
    :mental
]

EXTRAORDINARY_PERCEPTIONS =
[
    :dream,
    :vision
]

PERCEPTION_STAGES =
[
    :indeterminate, # Perceive an object without knowing its features.
    :determinate,   # When an object is clearly known.
    :rerecognition  # When one is able to re-recognize an object on the basis of memory.
]

class KB
    def get_thing_knowledge(args = {})
        raise "Can't search KB by thing: no thing set in #{args.inspect}" unless args.has_key?(:thing)
        _get_knowledge(@by_thing[args[:thing]], args)
    end

    def get_connector_knowledge(args = {})
        raise "Can't search KB by connector: no connector set in #{args.inspect}" unless args.has_key?(:connector)
        _get_knowledge(@by_connector[args[:connector]], args)
    end

    def get_property_knowledge(args = {})
        raise "Can't search KB by property: no property set in #{args.inspect}" unless args.has_key?(:property)
        _get_knowledge(@by_prop[args[:property]], args)
    end

    def add_knowledge(args = {})
        _init_indices
        # FIXME: If basic args already exist, ideally we'd reinforce the memory.
        q = KBQuanta.new(args)
        _add(q)
    end

    private
    def _init_indices
        if !@initialized
            @initialized  = true
            @by_thing     = {}
            @by_connector = {}
            @by_prop      = {}
        end
    end

    def _add(quanta)
        Log.debug("Adding #{quanta.inspect}", 6)
        _init_indices
        
        @by_thing[quanta.thing]         ||= []
        @by_connector[quanta.connector] ||= []
        @by_prop[quanta.property]       ||= []

        _add_to_list(@by_thing[quanta.thing],         quanta)
        _add_to_list(@by_connector[quanta.connector], quanta)
        _add_to_list(@by_prop[quanta.property],       quanta)
        return quanta
    end

    def _add_to_list(list, quanta)
        if preexisting = _find(list, quanta)
            preexisting.add_args(quanta.args)
        else
            list << quanta
        end
    end

    def _get_knowledge(list, args = {})
        _init_indices
        q = KBQuanta.new(args)
        _find(list, q)
    end

    def _find(list, quanta)
        return nil if list.nil?
        list.find { |q| q.hash == quanta.hash }
    end
end