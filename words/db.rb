require './util/packer'
require './words/words'

class Lexicon
    include Packer
    include Words

    def self.packable
        [:associations, :lexemes]
    end

    def unpack_custom(args)
        # Fix what would otherwise be duplicate references in associations.
        @associations.each do |association_type, sets|
            sets.map! do |s|
                s.map do |l|
                    l = self.get_lexeme(l.lemma)
                end
            end
        end
    end

    attr_accessor :default_lexeme

    def initialize(raws_db = nil, dict_dir = './words/dict')
        @associations = {}

        @lexemes = {}

        # Read in some basic noun & adjective information from the raws db.
        WordParser.read_raws(self, raws_db) if raws_db
        # Read in words from the dictionary directory.
        WordParser.load_dictionary(self, dict_dir)
    end

    # Generic Association Methods

    def associate(words, association_type)
        Log.debug([words, association_type], 7)
        words.map! { |w| add_lexeme(w) }

        @associations[association_type] ||= []
        # Find and remove old set; just for synonyms?
=begin
        @associations[association_type].each do |set|
            if !(set & words).empty?
                Log.debug("Deleting past association set #{set.inspect} because of #{words.inspect}")
                words = (words + set.to_a).uniq
                @associations[association_type].delete(set)
            end
        end
=end

        @associations[association_type] << Set.new(words)
    end

    def associations_of(word, association_type)
        lexeme = add_lexeme(word)
        @associations[association_type] ||= []
        @associations[association_type].select { |set| set.include?(lexeme) }.map { |set| set.to_a - [lexeme] }
    end

    def associated_lexemes_of(word, association_type)
        associations_of(word, association_type).flatten
    end

    def associated_words_of(word, association_type)
        associated_lexemes_of(word, association_type).map(&:lemma)
    end

    def get_associations_by_type(word, association_type, type)
        lexemes = associated_lexemes_of(word, association_type)
        lexemes.select do |l|
            l.types.include?(type)
        end
    end

    def get_sets_with(words, association_type)
        words = words.map { |w| add_lexeme(w) }
        @associations[association_type] ||= []
        @associations[association_type].find_all { |s| words.all? { |w| s.include?(w) } }
    end

    def get_type_from_sets_with(words, association_type, type)
        sets = get_sets_with(words, association_type)

        lexemes = []
        sets.each { |s| s.each { |l| lexemes << l if l.types.include?(type) } }
        lexemes
    end

    def synonyms_of(word)
        associated_words_of(word, :synonym)
    end

    # Verb & Preposition Association Methods

    def add_case_for_verb_preposition(case_name, verb = nil, preposition = nil)
        add_lexeme(case_name,   [:grammar_case, :noun, :base])
        add_lexeme(verb,        [:verb, :base]) if verb
        add_lexeme(preposition, [:preposition, :base]) if preposition

        association_type = if verb && preposition
            :preposition_case # Verb/preposition case
        elsif preposition
            :default_preposition # preposition case, for any verb
        elsif verb
            :default_case_for_verb # Verb/no preposition case. Only one for each verb.
        else
            :default_case_for_any_verb # Case when no preposition, for any verb. There will only be one.
        end

        associate([verb, preposition, case_name].compact, association_type)
    end

    def prep_for_verb(verb, case_name)
        prepositions     = get_type_from_sets_with([verb, case_name], :preposition_case, :preposition)
        def_prepositions = get_type_from_sets_with([      case_name], :default_preposition, :preposition)

        prepositions = def_prepositions if prepositions.empty?
        preposition = prepositions.first.lemma if prepositions.first
    end

    def case_for_verb(verb, preposition = nil)
        cases = []
        if preposition
            cases     = get_type_from_sets_with([verb, preposition], :preposition_case, :grammar_case)
            def_cases = get_type_from_sets_with([      preposition], :default_preposition, :grammar_case)
        else
            cases     = get_type_from_sets_with([verb], :default_case_for_verb, :grammar_case)
            def_cases = get_type_from_sets_with([], :default_case_for_any_verb, :grammar_case)
        end

        cases = def_cases if cases.empty?
        cases.first.lemma
    end

    # Conjugation Methods

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
