=begin
Grammar in Bushido Mongers uses concepts from phrase structure grammar, generally following constituency relations, but not based on any particular sub-theory.

http://en.wikipedia.org/wiki/Constituent_(linguistics)

PTNodes are the nodes of the tree, with further differentiation between internal nodes (nodes with node children) and leaf nodes. Internal nodes should not have non-node (i.e. symbol) children, and leaf nodes should not have node children, but in practice this is not strictly enforced.

The sentence structures have been designed to be as flexible as possible given their current basic nature. For example, descriptor hashes (see ./game/descriptors) or symbols can be passed in as nouns in any context, and many placements will also accept pre-created parts of speech (all the PTNode subclasses defined under Sentence). Verb conjugation is dependent on both abnormal word knowledge and generic rules, which work for most cases.
=end

module Words
    # Each node in the tree is either a root node, a branch node, or a leaf node.
    class ParseTree
        attr_accessor :root
        class PTNode
=begin
            The nominative case indicates the subject of a finite verb: We went to the store.
            The accusative case indicates the direct object of a verb: The clerk remembered us.
            The dative case indicates the indirect object of a verb: The clerk gave us a discount. or The clerk gave a discount to us.
            The ablative case indicates movement from something, or cause: The victim went from us to see the doctor. and He was unhappy because of depression.
            The genitive case, which roughly corresponds to English's possessive case and preposition of, indicates the possessor of another noun: John's book was on the table. and The pages of the book turned yellow.
            The vocative case indicates an addressee: John, are you all right? or simply Hello, John!
            The locative case (loc) indicates a location: We live in China.
            The lative case (lat) indicates motion to a location. It corresponds to the English prepositions "to" and "into".
            The instrumental case indicates an object used in performing an action: We wiped the floor with a mop. and Written by hand.
=end
            CASE = [:nominative, :accusative, :dative, :genitive, :vocative, :ablative, :locative, :instrumental]
            attr_accessor :case
            TYPE = [:sentence, :noun_phrase, :verb_phrase, :noun, :verb, :determiner]

            # Children in PTInternalNodes are other PTInternalNodes or PTLeafs. Children in PTLeaves are strings.
            attr_accessor :children

            def initialize(*children)
                raise(StandardError, "Can't instantiate PTNode class!") if self.class == PTNode
                @children = children.flatten
            end

            def to_s
                @children.join(" ")
            end

            def to_sym
                self.to_s.to_sym
            end
        end

        class PTInternalNode < PTNode
            # Uncomment this to display parens around each parent node.
#           def to_s
#               "(" + @children.join(" ") + ")"
#           end
        end

        class PTLeaf < PTNode
        end

        def initialize(*args)
            @root = PTInternalNode.new(*args)
        end

        def to_s
            @root.to_s
        end
    end

    class Sentence < ParseTree
        # Most of the time, we only want to print spaces between words.
        # Sometimes we want commas, spaces, and ands.
        # TODO - make coordination more generic: http://en.wikipedia.org/wiki/Coordination_(linguistics)
        module Listable
            def to_s
                if @children.size > 1 && @list
                    strings = @children.map(&:to_s)
                    last = strings.pop
                    strings.join(", ") + " and " + last
                else
                    super
                end
            end
        end

        # http://en.wikipedia.org/wiki/Subordinate_clause
        # TODO
        class RelativeClause < ParseTree::PTInternalNode
        end

        class Preposition < ParseTree::PTLeaf; end

        class PrepositionalPhrase < ParseTree::PTInternalNode
        end

        # Types: prepositional (during), infinitive (to work hard)
        # adpositions: preposition (by jove), circumpositions (from then on).
        class AdverbPhrase < ParseTree::PTInternalNode
            USED_ARGS = [:target, :tool, :destination, :receiver, :result]

            # The type is the part of the args being used to generate an adverb phrase.
            # args must be defined.
            def initialize(type, args)
                handled = false

                # Based on noun and argument information, decide which preposition to use, if any.
                case type
                when :target
                    prep = Words.db.get_preposition(args[:verb], :accusative)
                    Log.debug([:target, args[:verb], prep], 8)
                    if prep
                        super(prep, NounPhrase.new(args[type]))
                    else
                        super(NounPhrase.new(args[type]))
                    end
                    handled = true
                when :tool
                    super(noun_phrase_with_prep(type, args, :instrumental))
                    handled = true
                when :destination
                    # TODO - s.b. 'into' when moving to indoor locations
                    super(noun_phrase_with_prep(type, args, :lative))
                    handled = true
                when :location
                    super(noun_phrase_with_prep(type, args, :locative))
                    handled = true
                when :receiver
                    super(noun_phrase_with_prep(type, args, :dative))
                    raise NotImplementedError
                    # In Modern English, an indirect object is often expressed with a prepositional phrase of "to" or "for". If there is a direct object, the indirect object can be expressed by an object pronoun placed between the verb and the direct object. For example, "He gave that to me" and "He built a snowman for me" are the same as "He gave me that" and "He built me a snowman". 
                when :result
                    # Eventually this will be more complex, and describe either
                    # how the blow was evaded (parry, blocked, hit armor, etc)
                    # or how and where the blow hit.
                    case args[type]
                    when :hit
                        super(:",", :hitting)
                    when :miss
                        super(:",", :missing)
                    end
                end

                # We don't want to generate this again for other verbs and so forth.
                args.delete(type) if handled
            end

            private
            def noun_phrase_with_prep(type, args, prep_case)
                prep = Words.db.get_preposition(args[:verb], prep_case) || Words.db.default_prep_for_case(prep_case)
                Log.debug([args[type], args[:verb], prep], 8)
                [prep, NounPhrase.new(args[type])]
            end
        end

        # Four kinds of adjectives:
        # attributive: part of the NP. "happy people". Could be a premodifier (adj) or postmodifier (usually adj phrase)
        # predicative: uses linking copula (usually noun) to attach to noun. "The people are happy."
        # absolute: separate from noun; typically modifies subject or closest noun.
        # nominal: act almost as nouns; when noun is elided or replaces noun; "the meek shall inherit"

        # TODO - handle premodifiers and postmodifiers
        # TODO - handle participles
        class AdjectivePhrase < ParseTree::PTInternalNode; end

        class VerbPhrase < ParseTree::PTInternalNode
            include Listable
            # modal auxiliary: will, has
            # modal semi-auxiliary: be going to
            # TODO - add modals based on tense/aspect
            def initialize(verbs, args = {})
                verbs = Array(verbs)
                @children = verbs.map do |verb|
                    Verb.new(verb, args)
                end

                @children += AdverbPhrase::USED_ARGS.select { |arg| args.has_key?(arg) }.collect do |arg|
                    AdverbPhrase.new(arg, args.merge(:verb=>verbs.last))
                end

                if args[:subject_complement]
                    # FIXME: Technically we're not supposed to insert symbol children into PTInternalNode, but hack it.
                    # Subject complements can be adjectives or nouns (or NPs). How should we distinguish?
                    # Maybe generate during copula creation...
                    @children += Array(args[:subject_complement])
                end

                # FIXME - listing won't work while AdverbPhrases are children of VerbPhrase. Add to last V to form second VP?
                @list = (verbs.size > 1)
            end
        end

        class NounPhrase < ParseTree::PTInternalNode
            include Listable

            def initialize(nouns)
                # can't call Array(hash) because it decomposes to tuples
                nouns = ((Hash === nouns) ? [nouns] : Array(nouns))

                if nouns.all? { |n| n.is_a?(ParseTree::PTNode) }
                    # Nouns already created; just attach them.
                    super(nouns)
                    return
                end

                nouns.map! do |noun|
                    hash = {}
                    case noun
                    when Hash
                        # Decompose descriptor hashes into noun name, modifiers, and possession info.
                        hash[:monicker] = noun[:monicker]
                        raise TypeError unless [String, Symbol].include?(hash[:monicker].class)

                        hash[:adjectives] = Array(noun[:adjectives])
                        if noun[:properties]
                            hash[:adjectives] += Array(noun[:properties][:adjectives])
                        end

                        hash[:definite] == noun[:definite] if noun[:definite]

                        hash[:possessor_info] = noun[:possessor_info]if noun[:possessor_info]
                    else
                        hash[:monicker] = noun
                    end
                    hash
                end

                if @list = (nouns.size > 1)
                    super(
                    nouns.map do |noun|
                        children = generate_children(noun)
                        children.size > 1 ? NounPhrase.new(children) : children.first
                    end
                    )
                else
                    super(generate_children(nouns.first))
                end
            end

            private
            def generate_children(noun)
                monicker = noun[:monicker]
                children = []

                if monicker.is_a?(ParseTree::PTNode)
                    # Just return the PTNode.
                    return [monicker]
                end

                if noun[:adjectives]
                    noun[:adjectives].each do |adj|
                        adj = Adjective.new(adj) unless adj.is_a?(Adjective)
                        children << adj
                    end
                end

                children << Noun.new(monicker)

                if determiner = Determiner.new_for_noun(noun, children.first, noun[:definite])
                    children.insert(0, determiner)
                end

                children
            end
        end

        class Adjective < ParseTree::PTLeaf
            def self.ordered_adjectives
                {
                    1 => [:first,   :"1st"],
                    2 => [:second,  :"2nd"],
                    3 => [:third,   :"3rd"],
                    4 => [:fourth,  :"4th"],
                    5 => [:fifth,   :"5th"],
                    6 => [:sixth,   :"6th"],
                    7 => [:seventh, :"7th"],
                    8 => [:eighth,  :"8th"],
                    9 => [:ninth,   :"9th"]
                }
            end

            def self.ordered?(word)
                number = ordered_adjectives.find { |k, v| v.include?(word) }
                Log.debug(number)
                number
            end

            def self.adjective?(word)
                Words.db.all_pos(:adjective).include?(word) ||
                ordered_adjectives.any? { |k, v| v.include?(word) }
            end
        end

        # http://en.wikipedia.org/wiki/English_verbs
        # http://en.wikipedia.org/wiki/Predicate_(grammar)
        # http://en.wikipedia.org/wiki/Phrasal_verb
        # http://www.verbix.com/webverbix/English/have.html
        class Verb < ParseTree::PTLeaf
            def initialize(verb, args = {})
                super(Verb.state_conjugate(verb, args[:state]))
            end

            # Used for adding modals, aspects, etc.
            def self.state_conjugate(verb, state)
                case state.aspect
                when :stative
                    # TODO - Thus 'shall' is used with the meaning of obligation and 'will' with the meaning of desire or intention.
                    case state.tense
                    when :future
                        [conjugate(:will, State.new), verb]
                    else
                        [conjugate(verb, state)]
                    end
                when :progressive
                    be_state = State.new
                    # Do other state fields need copying here?
                    be_state.person = state.person
                    case state.voice
                    when :active
                        [conjugate(:be, be_state), gerund_participle(verb)]
                    when :passive
                        [conjugate(:be, be_state), past_participle(verb)]
                    else
                        raise(StandardError, "Invalid voice #{state.voice}!")
                    end
                else
                    raise(NotImplementedError)
                end
            end

            # Used for conjugating a single verb.
            # http://en.wikipedia.org/wiki/List_of_English_irregular_verbs
            def self.conjugate(infinitive, state)
                if Words.db.conjugation_for?(infinitive, state)
                    return Words.db.conjugate(infinitive, state)
                end

                infinitive = infinitive.to_s
                # Regular conjugation.
                infinitive = case state.tense
                when :present
                    if state.person == :third
                        sibilant?(infinitive) ? "#{infinitive}es" : "#{infinitive}s"
                    else
                        infinitive
                    end
                when :past
                    # Double the ending letter, if necessary.
                    # TODO - add exceptions to dictionary rather than hard-coding here.
                    unless [:detect, :inspect, :grasp].include?(infinitive.to_sym)
                        infinitive.gsub!(/([nbpt])$/, '\1\1')
                    end
                    # drop any ending 'e'
                    infinitive.sub!(/e$/, '')
                    infinitive += 'ed'
                when :future
                    # Handled in state_conjugate.
                    raise(NotImplementedError)
                end
            end

            # [One participle], called variously the present, active, imperfect,
            # or progressive participle, is identical in form to the gerund;
            # the term present participle is sometimes used to include the
            # gerund. The term gerund-participle is also used.
            def self.gerund_participle(infinitive)
                # handle irregular forms.
                case infinitive
                when :be
                    :being
                else
                    # Regular form.
                    infinitive = infinitive.to_s
                    # drop any ending 'e'
                    infinitive.sub!(/e$/, '')
                    infinitive += 'ing'
                end
            end

            # [The other participle], called variously the past, passive, or
            # perfect participle, is usually identical to the verb's preterite
            # (past tense) form, though in irregular verbs the two usually differ.
            def self.past_participle(infinitive)
                # handle irregular forms.
                # TODO - put these in dictionary.
                case infinitive
                when :do
                    :done
                when :eat
                    :eaten
                when :write
                    :written
                when :beat
                    :beaten
                when :wear
                    :worn
                else
                    # Regular form.
                    state = State.new
                    state.tense = :past
                    conjugate(infinitive, state)
                end
            end

            # However if the base form ends in one of the sibilant sounds
            # (/s/, /z/, /ʃ/, /ʒ/, /tʃ/, /dʒ/), and its spelling does not end in a
            # silent e, then -es is added: buzz → buzzes; catch → catches. Verbs
            # ending in a consonant plus o also typically add -es: veto → vetoes.
            def self.sibilant?(infinitive)
                infinitive = infinitive.to_s if Symbol === infinitive
                # First stab.
                infinitive[-1].chr == 's' ||
                (Words::CONSONANTS.include?(infinitive[-2].chr) && infinitive[-1].chr == 'o')
            end
        end

        # FIXME: Handle Gerunds
        class Noun < ParseTree::PTLeaf
            def initialize(noun)
                @children = [Noun.gen_noun_text(noun)]
            end

            def self.gen_noun_text(noun)
                if noun.respond_to?(:name)
                    noun.name
                elsif !noun.is_a?(String) && !noun.is_a?(Symbol)
                    noun.class.to_s.downcase
                else
                    noun
                end
            end

            # Determine whether noun is definite (e.g. uses 'the') or indefinite (e.g. a/an)
            # http://en.wikipedia.org/wiki/Definiteness
            # TODO - store always-definite words in dictionary
            def self.definite?(noun)
                return false unless noun.respond_to?(:to_sym)
                case noun.to_sym
                when :east, :west, :north, :south
                    true
                else
                    false
                end
            end

            def self.needs_article?(noun)
                !Noun.proper?(noun) && !Noun.pronoun?(noun)
            end

            def self.proper?(noun)
                # TODO - if the descriptor has a :name, it's probably a proper noun.
                noun = gen_noun_text(noun)
                if noun.is_a?(Noun)
                    noun.children.last.to_s.capitalized?
                elsif noun.respond_to?(:to_s)
                    noun.to_s.capitalized?
                else
                    false
                end
            end

            def self.noun?(word)
                Words.db.all_pos(:noun).include?(word) || definite?(word) || pronoun?(word)
            end

            # http://en.wikipedia.org/wiki/Pro-form
            # TODO: We'll want to stand in pronouns for certain words (based
            # on previous usage) to avoid repetition. Maybe. Not even DF does this.
            # N.B. There's overlap between certain pronouns and certain possessive determiners.
            def self.pronoun?(noun)
                # If it's e.g. a BushidoObject then it's not a pronoun.
                return false unless noun.respond_to?(:to_sym)
                case noun.to_sym
                # Subject person pronouns.
                when :I, :i, :you, :he, :she, :it, :we, :they, :who
                    true
                # Possessive pronouns.
                when :mine, :yours, :his, :hers, :its, :ours, :theirs
                    true
                # Object person pronouns.
                when :me, :you, :him, :her, :it, :us, :them, :whom
                    true
                # Existentials.
                when :someone, :somebody, :one, :some
                    true
                # Demonstratives: http://en.wikipedia.org/wiki/Demonstrative
                when :this, :that, :these, :those, :this_one, :that_one
                    true
                else
                    false
                end
            end

            # TODO - use
            def plural?
                return true if @plural
                # Otherwise, make a nasty first-guess.
                @main[-1] == 's' || @main.match(' and ')
            end

            # TODO - use
            def pluralize
                # Make a nasty first-approximation.
                if (plural? && noun?) || (!plural? && verb?)
                    @main.gsub!(/s?$/, 's')
                end
                self
            end
        end

        class Determiner < ParseTree::PTLeaf
            class << self
                def new_for_noun(noun, first_word, definite)
                    if noun[:possessor_info]
                        Possessive.new(noun[:possessor_info])
                    elsif Noun.needs_article?(noun[:monicker])
                        Article.new(noun[:monicker], first_word, definite)
                    else
                        nil
                    end
                end
            end
        end

        class Possessive < Determiner
            def initialize(possessor_info)
                # Possessive picked based on a) person and b) gender.
                super(
                case possessor_info[:person]
                # Mirroring State's :person field here.
                when :first
                    :my
                when :second, :second_plural
                    :your
                when :third
                    case possessor_info[:gender]
                    when :male
                        :his
                    when :female
                        :her
                    when :neutral
                        :zir
                    when :inanimate
                        :its
                    end
                when :first_plural
                    :our
                when :third_plural
                    :their
                end
                )
            end

            # N.B. There's overlap between certain pronouns and certain possessive determiners.
            def self.possessive?(det)
                case det.to_sym
                when :my, :your, :his, :her, :its, :our, :their
                    true
                end
            end
        end

        class Article < Determiner
            def initialize(noun, first_word=nil, definite=nil)
                if Article.article?(noun)
                    super(noun)
                elsif definite || Noun.definite?(noun)
                    super(:the)
                else
                    # TODO - 'some' for plural nouns
                    first_word = noun unless first_word
                    if Article.use_an?(first_word)
                        super(:an)
                    else
                        super(:a)
                    end
                end
            end

            def definite?
                return true if @children == [:the]
            end

            def self.use_an?(word)
                case word.to_sym
                when :honorable, :honest
                    true
                when :union, :united, :unicorn, :used, :one
                    false
                else
                    !!word.to_s.match(/^[aeiouy]/)
                end
            end

            def self.article?(art)
                case art.to_sym
                when :the, :a, :an, :some
                    true
                else
                    false
                end
            end
        end

        def to_s
            super.sentence
        end
    end
end
