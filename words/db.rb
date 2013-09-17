require './util/packer'
require './words/words'

class WordDB
    include Packer
    include Words

    def self.packable
        [:groups, :associations, :conjugations, :verb_case_maps, :verb_default_case, :lexemes, :lemmas, :derivations]
    end

    def initialize
        @groups       = []
        @associations = []
        @conjugations = {}

        @verb_case_maps     = {}
        @verb_default_case  = {}

        @lexemes = []
        @lemmas  = []
        @derivations = []
    end

    def collect_groups(*list_of_words)
        list_of_words.collect do |word|
            if Symbol === word
                find_group_for(word)
            else
                # Check if a definition exists
                if matched = find_group_for(word, false)
                    matched
                elsif mergee = find_group_matching_any(word, false)
                    merge(mergee, word)
                else
                    @groups << WordGroup.new(word)
                    @groups.last
                end
            end
        end
    end

    def find_group_matching_any(word, verbose=true)
        case word
        when Hash
            # FIXME - O(n^2) for all groups
            matching = @groups.select { |group| word.any? { |pos, w| group[pos] == w } }
            raise(StandardError, "Duplicate word groups found in #{self.class} for #{word.inspect}.") unless matching.size < 2
            Log.debug("No word group '#{word.inspect}' found!") if matching.size <= 0 && verbose
            matching.first
        when Symbol,String, WordGroup
            # Symbol,String should've been caught by find_group_for already
            # WordGroup would ideally be checked, but it's not implemented yet.
            raise(NotImplementedError)
        else
            Log.debug("Couldn't find group matching word class #{word.class}")
        end
    end

    def all_pos(pos)
        @groups.select { |g| g.has?(pos) }.collect { |g| g[pos] }
    end

    # requirements: mergee is a WordGroup, merger is a Hash
    def merge(mergee, merger)
        Log.debug(["Merging:", mergee, merger])
        merger.each { |k, v| mergee[k] = v }
        mergee
    end

    def associate_groups(*list_of_groups)
        # nothing to associate
        return if list_of_groups.size < 2

        # Find and remove old associations
        @associations.each do |set|
            if !(set & list_of_groups).empty?
                list_of_groups = (list_of_groups + set.to_a).uniq
                @associations.delete(set)
            end
        end

        @associations << Set.new(list_of_groups)
    end

    def add_family(*list_of_words)
        Log.debug("Adding family #{list_of_words.inspect}", 6)
        list_of_groups = collect_groups(*list_of_words)
        associate_groups(*list_of_groups)
        list_of_groups
    end

    def add_verb_preposition(verb, preposition, case_name)
        @verb_case_maps[verb] ||= {}
        if preposition
            @verb_case_maps[verb][case_name] = preposition
        else
            @verb_default_case[verb] = case_name
        end
    end

    # Get a list of related groups
    def get_related_groups(word_or_group)
        group = find_group_for(word_or_group)
        return nil if group.nil?
        @associations.each do |set|
            if set.include?(group)
                return set.to_a - [group]
            end
        end
        nil
    end

    # Get a list of related words with the same part of speech as the query word
    def get_related_words(word)
        group = find_group_for(word)
        return nil if group.nil?
        pos = group.part_of_speech(word)
        @associations.each do |set|
            if set.include?(group)
                return (set.to_a - [group]).select { |g| g.has?(pos) }.collect { |g| g[pos] }
            end
        end
        nil
    end

    # Verbs have different prepositions for different cases.
    def get_prep_map_for_verb(verb)
        @verb_case_maps[:default].dup.merge(@verb_case_maps[verb] || {})
    end

    # Verbs have different prepositions for different designations.
    def get_prep_for_verb(verb, case_name)
        @verb_case_maps[verb] ||= {}
        @verb_case_maps[verb][case_name] || @verb_case_maps[:default][case_name]
    end

    def get_default_case_for_verb(verb)
        @verb_default_case[verb] || @verb_default_case[:default]
    end

    # For 'special' conjugations. Basic rules are in Verb::conjugate.
    def conjugate(infinitive, state)
        @conjugations[state][infinitive]
    end

    def conjugation_for?(infinitive, state)
        !!(@conjugations[state] && @conjugations[state][infinitive])
    end

    def add_conjugation(infinitive, state, expr)
        @conjugations[state] ||= {}
        @conjugations[state][infinitive] = expr
    end

    #  Words::State::FIELDS[:person] => [:first, :second, :third, :first_plural, :second_plural, :third_plural],
    def add_conjugation_by_person(infinitive, state, list)
        first_person = list.first
        Words::State::FIELDS[:person].each do |person|
            curr_state = state.dup

            curr_state.person = person

            expr = list.shift
            if expr
                add_conjugation(infinitive, curr_state, expr)
            else
                # If the list is unfilled, use the first person as default.
                add_conjugation(infinitive, curr_state, first_person)
            end
        end
    end

    private
    def find_group_for(word, verbose = true)
        case word
        when Symbol,String
            matching = @groups.select { |group| group.contains?(word.to_sym) }
            Log.debug("Warning - '#{word}' appears in more than one word group") if matching.size > 1
            Log.debug("No reference to '#{word}' found!", 9) if matching.size <= 0 && verbose
            matching.first
        when WordGroup, Hash
            matching = @groups.select { |group| group == word.to_sym }
            raise(StandardError, "Duplicate word groups found in #{self.class} for #{word.inspect}.") unless matching.size < 2
            Log.debug("No word group '#{word.inspect}' found!") if matching.size <= 0 && verbose
            matching.first
        else
            raise(ArgumentError, "Can't find groups given type #{word.class}.")
        end
    end

    public
    def add_lexeme(lemma, l_type, args = {})
        lemma = lemma.to_sym
        Log.debug("db.add_lexeme(#{lemma.inspect} (#{l_type.inspect}) #{args.inspect})", 8)
        if !@lemmas.include?(lemma)
            @lemmas  << lemma
            l = Lexicon::Lexeme.new(lemma, l_type, args)
            @lexemes << l
        else
            l = get_lexeme(lemma)
            l.add_type(l_type)
            l.add_args(args)
        end
        l
    end

    def get_lexeme(lemma)
        @lexemes.find { |l| l.lemma == lemma }
    end

    def lexemes_of_type(l_type)
        @lexemes.find_all { |l| l.types.include?(l_type) }
    end

    def words_of_type(l_type)
        lexemes_of_type(l_type).map(&:lemma)
    end

    def add_derivation(derivation)
        @derivations << derivation
        if @lemmas.include?(derivation.derived.lemma)
            Log.debug("adding derivation of pre-existing lexeme #{derivation.derived}")
        else
            @lexemes << derivation.derived
            @lemmas  << derivation.derived.lemma
        end
        derivation.derived
    end
end

class WordGroup
    def initialize(args={})
        @parts_of_speech = args.to_sym
    end

    # Values should all be converted to symbols already
    def to_sym
        self
    end

    def [](part_of_speech)
        parts_of_speech[part_of_speech]
    end

    def []=(part_of_speech, word)
        parts_of_speech[part_of_speech] = word
    end

    def part_of_speech(word)
        raise(ArgumentError, "#{word} is not a member of #{parts_of_speech.inspect}.") unless contains?(word)
        parts_of_speech.find { |k,v| v == word }.first
    end

    def has?(part_of_speech)
        parts_of_speech.has_key?(part_of_speech)
    end

    def contains?(word)
        parts_of_speech.values.include?(word)
    end

    def ==(other)
        case other
        when WordGroup
            parts_of_speech == other.parts_of_speech
        when Hash
            parts_of_speech == other
        else
            raise(NotImplementedError, "Can't compare wordgroup to #{other.class}.")
        end
    end

    protected
    attr_reader :parts_of_speech
end
