require 'util/basic'
require 'util/formatting'
require 'set'
require 'util/log'
require 'words/parser'

# TODO - add info on acceptable/used arguments to generators

module Words
    TYPES = :noun, :name, :verb, :adjective, :adverb

    VOWELS = ['a', 'e', 'i', 'o', 'u']
    CONSONANTS = ('a'..'z').to_a - VOWELS

    def self.register_db(db)
        @db = db
    end

    def self.db
        if @db
            @db
        else
            WordParser.load
        end
    end

    class Adjective
        def self.adv(adj)
            adv = adj.to_s if Symbol === adj
            adv = adv.gsub(/le$/, '').
                      gsub(/ic$/, 'ical').
                      gsub(/y$/, 'i')
            "#{adv}ly"
        end

        def self.noun(adj)
            noun = adj.to_s if Symbol === adj
            noun = noun.gsub(/y$/, 'i')
            "#{noun}ness"
        end
    end

    # http://en.wikipedia.org/wiki/English_verbs#Syntactic_constructions
    # http://en.wikipedia.org/wiki/English_clause_syntax

    # TODO - distinguish between patient (action receiver) and direct object (part of sentence), esp. useful for passive case.
    class State
        ASPECTS = [:perfect, :imperfect, :habitual, :stative, :progressive]
        TENSE   = [:present, :past]
        MOOD    = [:indicative, :subjunctive, :imperative]
        PERSON  = [:first, :second, :third, :first_plural, :second_plural, :third_plural]
        VOICE   = [:active, :passive]

        attr_accessor :aspect, :tense, :mood, :person, :voice

        def initialize
            set_default_state
        end

        def set_default_state
            @aspect = :stative
            @tense  = :present
            @mood   = :indicative
            @person = :third
            @voice  = :active
        end
    end

    # Manipulating sentences:
    # http://en.wikipedia.org/wiki/Constituent_(linguistics)

=begin
    Case:
    Noun:   The nominative case indicates the subject of a finite verb: We went to the store.
    Noun:   The accusative case indicates the direct object of a verb: The clerk remembered us.
    Noun:   The dative case indicates the indirect object of a verb: The clerk gave us a discount. or The clerk gave a discount to us.
    Noun:   The genitive case, which roughly corresponds to English's possessive case and preposition of, indicates the possessor of another noun: John's book was on the table. and The pages of the book turned yellow.
    Noun:   The vocative case indicates an addressee: John, are you all right? or simply Hello, John!
    Phrase: The ablative case indicates movement from something, or cause: The victim went from us to see the doctor. and He was unhappy because of depression.
    Phrase: The locative case indicates a location: We live in China.
    Phrase: The instrumental case indicates an object used in performing an action: We wiped the floor with a mop. and Written by hand.
=end

    # Each node in the tree is either a root node, a branch node, or a leaf node.
    class ParseTree
        attr_accessor :root
        class PTNode
            CASE = [:nominative, :accusative, :dative, :genitive, :vocative, :ablative, :locative, :instrumental]
            attr_accessor :case
            TYPE = [:sentence, :noun_phrase, :verb_phrase, :noun, :verb, :determiner]

            # Children in PTInternalNodes are other PTInternalNodes or PTLeafs. Children in PTLeaves are strings.
            attr_accessor :children

            def initialize(*children)
                raise "Can't instantiate PTNode class!" if self.class == PTNode
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

        # Types: prepositional (during), infinitive (to work hard)
        # adpositions: preposition (by jove), circumpositions (from then on).
        class AdverbPhrase < ParseTree::PTInternalNode
            USED_ARGS = [:target, :tool, :result]

            # The type is the part of the args being used to generate an adverb phrase.
            # args must be defined.
            def initialize(type, args)
                @children = []
                handled = false

                # Based on noun and argument information, decide which preposition to use, if any.
                case type
                when :target
                    @children << NounPhrase.new(args[type])
                    handled = true
                when :tool
                    @children = [:with, NounPhrase.new(args[type])]
                    handled = true
                when :result
                    # Eventually this will be more complex, and describe either
                    # how the blow was evaded (parry, blocked, hit armor, etc)
                    # or how and where the blow hit.
                    case args[type]
                    when :hit
                        @children = [:",", :hitting]
                    when :miss
                        @children = [:",", :missing]
                    end
                end

                # We don't want to generate this again for other verbs and so forth.
                args.delete(type) if handled
            end
        end

        # Four kinds of adjectives:
        # attributive: part of the NP. "happy people". Could be a premodifier (adj) or postmodifier (usually adj phrase)
        # predicative: uses linking copula (usually noun) to attach to noun.
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
            attr_accessor :modal
            def initialize(verbs, args = {})
                verbs = Array(verbs)
                @children = verbs.map do |verb|
                    Verb.new(verb, args)
                end

                @children += AdverbPhrase::USED_ARGS.select { |arg| args.has_key?(arg) }.collect do |arg|
                    AdverbPhrase.new(arg, args)
                end

                @list = (verbs.size > 1)
            end
        end

        class NounPhrase < ParseTree::PTInternalNode
            include Listable
            def initialize(nouns)
                nouns = Array(nouns)

                if nouns.all? { |n| n.is_a?(ParseTree::PTNode) }
                    # Nouns already created; just attach them.
                    @children = nouns
                    return
                end

                @list = (nouns.size > 1)
                @children = nouns.map do |noun|
                    noun_with_article(noun)
                end
                @children.flatten!
            end

            def add_adjectives(*adjectives)
                raise "Don't know which noun to adjectivize of #{self.inspect}!" if @list
                # Insert adjectives between (potential) article but before the noun
                adjectives.each do |adj|
                    adj = Adjective.new(adj) unless adj.is_a?(Adjective)
                    @children.insert(-2, adj)
                end
            end

            private
            def noun_with_article(noun)
                if noun.is_a?(ParseTree::PTNode)
                    noun
                elsif Noun.needs_article?(noun)
                    children = [Article.new(noun), Noun.new(noun)]
                    # If it's a list, stuff the article-plus-noun into a sub-NP.
                    # Otherwise, just return the child array, which will be flattened out.
                    if @list
                        NounPhrase.new(children)
                    else
                        children
                    end
                else
                    Noun.new(noun)
                end
            end
        end

        class Adjective < ParseTree::PTLeaf; end

        # http://en.wikipedia.org/wiki/English_verbs
        # http://en.wikipedia.org/wiki/List_of_English_irregular_verbs
        # http://en.wikipedia.org/wiki/Predicate_(grammar)
        # http://en.wikipedia.org/wiki/Phrasal_verb
        # http://www.verbix.com/webverbix/English/have.html
        class Verb < ParseTree::PTLeaf
            def initialize(verb, args = {})
                state = args[:state] || State.new
                @children = [Verb.conjugate(verb, state)]

                # Insert a direct preposition, if it exists for the verb.
                if args[:target]
                    preposition = Words.db.get_preposition(verb)
                    @children << preposition if preposition
                end
            end

            def self.conjugate(infinitive, state = State.new)
                # Words::Conjugations for 'special' conjugations
                if {}.keys.include?(infinitive)
                    nil
                end

                # defaults
                infinitive = case state.tense
                when :present
                    if state.person == :third
                        sibilant?(infinitive) ? "#{infinitive}es" : "#{infinitive}s"
                    else
                        infinitive
                    end
                when :past
                    # Double the ending letter, if necessary.
                    infinitive.gsub!(/([nbpt])$/, '\1\1')
                    # drop any ending 'e'
                    infinitive.sub!(/e$/, '')
                    infinitive += 'ed'
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
            # FIXME: Base this on noun lookups?
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
                noun = gen_noun_text(noun)
                if noun.is_a?(Noun)
                    noun.children.last.to_s.capitalized?
                elsif noun.respond_to?(:to_s)
                    noun.to_s.capitalized?
                else
                    false
                end
            end

            # http://en.wikipedia.org/wiki/Pro-form
            # TODO: We'll want to stand in pronouns for certain words (based
            # on previous usage) to avoid repetition. Maybe. Not even DF does this.
            def self.pronoun?(noun)
                # If it's e.g. a BushidoObject then it's not a pronoun.
                return false unless noun.respond_to?(:to_sym)
                case noun.to_sym
                # Subject person pronouns.
                when :I, :we, :you, :he, :she, :it, :they, :who
                    true
                # Object person pronouns.
                when :me, :us, :you, :him, :her, :it, :them, :whom
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

        class Article < ParseTree::PTLeaf
            def initialize(noun)
                if Article.article?(noun)
                    super(noun)
                elsif Noun.definite?(noun)
                    super("the")
                else
                    # TODO - check for 'an' case - starts with a vowel or silent H
                    # TODO - 'some' for plural nouns
                    super("a")
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

    # TODO - action descriptors: The generic ninja generically slices the goat with genericness.
    def self.gen_sentence(args = {})
        subject = args[:subject] || args[:agent]
        verb    = args[:verb] || args[:action] || args[:command]

        # Subject is you in second person
        if !subject && args[:state] && args[:state].person == :second
            subject = :you
        end

        raise unless verb

        # Use an associated verb, if any exist.
        associated_verbs = Words.db.get_related_words(verb.to_sym)
        if associated_verbs && associated_verbs.size > 1
            verb = associated_verbs.rand
        end

        # TODO - Use expletive
        # TODO - expletive more often for second person
        #features = []
        #features << :expletive if Chance.take(:coin_toss)

        subject_np = Sentence::NounPhrase.new(subject)
        verb_np    = Sentence::VerbPhrase.new(verb, args)

        Sentence.new(subject_np, verb_np)
    end

    #:keywords=>[], :objects=>["Test NPC 23683", "Test NPC 35550", "Test Character"], :exits=>[:west], :name=>"b00"

    # Required/expected arg values: keywords objects exits
    def self.gen_room_description(args = {})
        @sentences = []

        args = args.merge(:action => :see)

        args[:state] = State.new
        args[:state].person = :second

        if args[:keywords].empty?
            @sentences << Words.gen_sentence(args.merge(:target => "boring room"))
        else
            @sentences << Words.gen_sentence(args.merge(:target => (args[:keywords].rand.to_s + " room")))
        end

        if args[:objects] && !args[:objects].empty?
            @sentences << Words.gen_sentence(args.merge(:target => args[:objects]))
        end

        args[:exits]

        @sentences.join(" ")
    end

    def self.gen_area_name(args = {})
        article = Sentence::Article.new(:the)
        noun    = Sentence::Noun.new(args[:type])
        name    = Sentence::NounPhrase.new([article, noun])
        keywords = args[:keywords]

        if keywords && !keywords.empty?
            name.add_adjectives(keywords.rand)
        end

#        descriptor = db.get_keyword_words(:abstract, :noun).rand

        name.to_s.title
    end
end
