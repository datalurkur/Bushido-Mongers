require './util/packer'
require './words/words'

class WordDB
    include Packer
    include Words

    def self.packable
        [:groups, :associations, :conjugations, :verb_case_maps, :verb_default_case, :lexemes, :lemmas, :derivations]
    end

    def unpack_custom(args)
        # Fix what would otherwise be duplicate references in associations.
        @associations.map! do |set|
            set.map! do |l|
                l = self.get_lexeme(l.lemma)
            end
        end
    end

    attr_accessor :associations

    def initialize(dict_dir = './words/dict')
        @associations = []
        @conjugations = {}

        @verb_case_maps     = {}
        @verb_default_case  = {}

        @lexemes = []
        @lemmas  = []
        @derivations = []

        WordParser.load_dictionary(self, dict_dir)
    end

    def read_raws(raws_db)
        WordParser.read_raws(self, raws_db)
    end

    # Generic Association Methods

    def associate(words, l_type)
        words.map! { |w| add_lexeme(w, l_type) }

        # nothing to associate
        return if words.size < 2

        # Find and remove old set
        @associations.each do |set|
            if !(set & words).empty?
                words = (words + set.to_a).uniq
                @associations.delete(set)
            end
        end

        @associations << Set.new(words)
    end

    def associated_lexemes_of(word)
        lexeme = add_lexeme(word)
        @associations.each do |set|
            if set.include?(lexeme)
                return (set.to_a - [lexeme])
            end
        end
        []
    end

    def associated_words_of(word)
        associated_lexemes_of(word).map(&:lemma)
    end

    def get_associations_by_type(word, type)
        lexemes = associated_lexemes_of(word)
        lexemes.select do |l|
            l.types.include?(type)
        end
    end

    def associated_verbs(word)
        get_associations_by_type(word, :verb).map(&:lemma)
    end

    # How do we decide which type to use? First POS?
#    def get_synonyms(word)
#        get_associations_by_type(word, word.types.first)
#    end

    # Verb & Preposition Association Methods

    def add_verb_preposition(verb, preposition, case_name)
        @verb_case_maps[verb] ||= {}
        if preposition
            @verb_case_maps[verb][case_name] = preposition
        else
            @verb_default_case[verb] = case_name
        end
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

    # Lexeme Methods

    def add_lexeme(word, l_type = [], args = {})
        lemma = word.is_a?(Lexicon::Lexeme) ? word.lemma : word.to_sym

        Log.debug("db.add_lexeme(#{lemma.inspect}, #{l_type.inspect}, #{args.inspect})", 8)
        if !@lemmas.include?(lemma)
            @lemmas  << lemma
            l = word.is_a?(Lexicon::Lexeme) ? word : Lexicon::Lexeme.new(lemma, l_type, args)
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

    # Derivation Methods

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
