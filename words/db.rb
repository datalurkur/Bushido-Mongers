require './util/packer'
require './words/words'

class Lexicon
    include Packer
    include Words

    def self.packable
        [:associations, :verb_case_maps, :verb_default_case, :lexemes]
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

    def initialize(raws_db = nil, dict_dir = './words/dict')
        @associations = []

        @verb_case_maps     = {}
        @verb_default_case  = {}

        @lexemes = {}

        # Read in some basic noun & adjective information from the raws db.
        WordParser.read_raws(self, raws_db) if raws_db
        # Read in words from the dictionary directory.
        WordParser.load_dictionary(self, dict_dir)
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

    # Look up conjugation by referencing the lexeme.
    def conjugate(infinitive, state)
        original = add_lexeme(infinitive, [:verb, :base])
        morphed  = original.args[:morphs][state]
        morphed.lemma
    end

    def conjugation_for?(infinitive, state)
        original = add_lexeme(infinitive, [:verb, :base])
        !!original.args[:morphs][state]
    end

    #  Words::State::FIELDS[:person] => [:first, :second, :third, :first_plural, :second_plural, :third_plural],
    def add_conjugation_by_person(infinitive, state, list)
        original = add_lexeme(infinitive, [:verb, :base])

        first_person = add_lexeme(list.first, [:verb, :morphed], :morph_type => state.with_person(:first))
        Log.debug(first_person, 5)

        Words::State::FIELDS[:person].each do |person|
            curr_state = state.with_person(person)

            if entry = list.shift
                morphed = add_lexeme(entry, [:verb, :morphed], :morph_type => curr_state)
                add_morph(:inflection, curr_state, original, morphed)
            else
                # If the list is unfilled, use the first person as default.
                add_morph(:inflection, curr_state, original, first_person)
            end
        end
    end

    # Lexeme Methods

    # If a lexeme is already in the list, the types and args given are added to the lexeme.
    def add_lexeme(word, l_type = [], args = {})
        Log.debug([word, l_type, args], 9)
        if word.is_a?(Lexeme)
            lexeme = get_lexeme(word.lemma)
            if lexeme.nil?
                lexeme = word
                @lexemes[lexeme.lemma] = lexeme
            end
            lexeme.add_type(l_type)
            lexeme.add_args(args)
        else
            if lexeme = get_lexeme(word.to_sym)
                lexeme.add_type(l_type)
                lexeme.add_args(args)
            else
                lexeme = Lexeme.new(word, l_type, args)
                Log.debug("Creating new lexeme #{lexeme.inspect}", 5)
                @lexemes[lexeme.lemma] = lexeme
            end
        end
        lexeme
    end

    def get_lexeme(lemma)
        @lexemes[lemma]
    end

    def lexemes_of_type(l_type)
        @lexemes.values.find_all { |l| l.types.include?(l_type) }
    end

    def base_lexemes_of_type(l_type)
        lexemes_of_type(l_type).select { |l| l.types.include?(:base) }
    end

    def words_of_type(l_type)
        lexemes_of_type(l_type).map(&:lemma)
    end

    # Derivation & Inflection Methods

    # Takes lexemes and returns the morphed lexeme.
    def add_morph(morph_type, pattern, original, morphed = nil)
        morph_class = MorphologicalRule.sym_to_class(morph_type)

        morphed = morph_class.default_lexeme(self, pattern, original) if morphed.nil?
        morph_class.check_consistency(pattern, original, morphed)

        # Mark morph pattern on original lexeme.
        if original.args[:morphs][pattern] && !(morphed.lemma == original.args[:morphs][pattern].lemma)
            Log.warning("Pattern #{pattern.inspect} already used for #{original.lemma}: was #{original.args[:morphs][pattern].lemma}, wants #{morphed.lemma}")
        end

        original = add_lexeme(original, [:base])
        original.args[:morphs][pattern] = morphed
        morphed  = add_lexeme(morphed,  [:morphed], :morph_type => pattern, :morphed_from => original)
    end
end
