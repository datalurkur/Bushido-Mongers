require 'util/basic'
require 'util/formatting'
require 'set'
require 'util/log'
require 'words/parser'

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
    module WordState
        class << self
            ASPECTS = [:perfect, :imperfect, :habitual, :stative, :progressive]
            TENSE   = [:present, :past]
            MOOD    = [:indicative, :subjunctive, :imperative]
            PERSON  = [:first, :second, :third, :first_plural, :second_plural, :third_plural]
            VOICE   = [:active, :passive]

            attr_accessor :aspect, :tense, :mood, :person, :voice

            def reset_state
                @aspect = :stative
                @tense  = :present
                @mood   = :indicative
                @person = :third
                @voice  = :active
            end
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
                raise "Can't instantiate parent class!" if self.class == PTNode
                @children = children.flatten
            end

            def to_s
                @children.join(" ")
            end
        end

        class PTInternalNode < PTNode
    #        def to_s
    #            "(" + @children.join(" ") + ")"
    #        end
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
        module PrintsAsList
            def to_s
                case @children.size
                when 0: ""
                when 1: @children.first.to_s
                else
                    if @print_as_list
                        strings = @children.map(&:to_s)
                        pop = strings.pop
                        strings.join(", ") + " and " + pop
                    else
                        super
                    end
                end
            end
        end

        # Types: prepositional (during), infinitive (to work hard)
        # FIXME: use
        class Phrase < ParseTree::PTInternalNode
        end

        class VerbPhrase < ParseTree::PTInternalNode
            # modal auxiliary: will, has
            # modal semi-auxiliary: be going to
            # FIXME: add modals based on tense/aspect
            attr_accessor :modal
            def initialize(verb, args = {})
                @children = [Verb.new(verb)]
                @children << NounPhrase.new(args[:dir_obj]) if args[:dir_obj]
                @children << NounPhrase.new(args[:ind_obj]) if args[:ind_obj]
            end
        end

        class NounPhrase < ParseTree::PTInternalNode
            include PrintsAsList
            def initialize(nouns)
                if Array === nouns
                    # At the bottom level, determiners will be added to NounPhrases.
                    if Determiner === nouns.first
                        @children = nouns
                    else
                        @children = nouns.map do |noun|
                            NounPhrase.new(determine(noun))
                        end
                        @print_as_list = true
                    end
                else
                    @children = determine(nouns)
                end
            end

            def determine(noun)
                if Noun.definite?(noun)
                    [Determiner.new(noun), Noun === noun ? noun : Noun.new(noun.class.to_s.downcase)]
                elsif noun.respond_to?(:name)
                    [Noun.new(noun.name)]
                else
                    [Noun.new(noun)]
                end
            end
        end

        # http://en.wikipedia.org/wiki/English_verbs
        # http://en.wikipedia.org/wiki/List_of_English_irregular_verbs
        # http://en.wikipedia.org/wiki/Predicate_(grammar)
        # http://en.wikipedia.org/wiki/Phrasal_verb
        # http://www.verbix.com/webverbix/English/have.html
        class Verb < ParseTree::PTLeaf
            def initialize(*children)
                @children = children.map { |t| Verb.conjugate(t) }
            end

            # FIXME: use
            def self.conjugate(infinitive, tense = WordState.tense, subject = WordState.person)
                # Words::Conjugations
                if {}.keys.include?(infinitive)
                    nil
                end

                # defaults
                infinitive = case tense
                when :present
                    if subject == :third
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
            # FIXME: http://en.wikipedia.org/wiki/Definiteness
            # FIXME: Base this on noun lookups?
            def self.definite?(noun)
                return !(noun.is_a?(String) || noun.is_a?(Symbol))
            end

            # FIXME: use
            def plural?
                return true if @plural
                # Otherwise, make a nasty first-guess.
                @main[-1] == 's' || @main.match(' and ')
            end

            # FIXME: use
            def pluralize
                # Make a nasty first-approximation.
                if (plural? && noun?) || (!plural? && verb?)
                    @main.gsub!(/s?$/, 's')
                end
                self
            end
        end

        class Determiner < ParseTree::PTLeaf
            def initialize(noun)
                @children = ["the"]
            end
        end

        def to_s
            super.sentence
        end
    end

    # FIXME: action descriptors: The generic ninja generically slices the goat with genericness.
    def self.gen_sentence(args = {})
        subject = args[:subject] || args[:agent]
        verb    = args[:verb] || args[:action]
        dir_obj = args[:target]
        ind_obj = args[:tool]

        raise unless verb

        # Use an associated verb, if any exist.
        associated_verbs = Words.db.get_related_words(verb.to_sym)
        if associated_verbs && associated_verbs.size > 1
            verb = associated_verbs.rand
        end

        # FIXME: expletive more often for second person
        # FIXME: Use expletive
        features = []
        features << :expletive if rand(2) == 0

=begin
            phrase, adverb = ''
            if synonym && matches = Words.find(:keyword => synonym)
                describer = matches.rand
                @subject.descriptors << describer.adjective
                @verb.descriptors << describer.adverb
                @verb.phrases << "with #{describer.noun}"
            end
=end

        subject_np = Sentence::NounPhrase.new(subject)
        verb_np    = Sentence::VerbPhrase.new(verb, :dir_obj => dir_obj, :ind_obj => ind_obj)

        Sentence.new(subject_np, verb_np)
    end

    #:keywords=>[], :contents=>[], :occupants=>["Test NPC 23683", "Test NPC 35550", "Test Character"], :exits=>[:west], :name=>"b00"

    def self.gen_room_description(args = {})
        WordState.person = :second
        
        @sentences = []

        if args[:keywords].empty?
            @sentences << Words.gen_sentence(:subject => "You", :action => "see", :target => "boring room")
        else
            @sentences << Words.gen_sentence(:subject => "You", :action => "see", :target => (args[:keywords].rand.to_s + " room"))
        end

        if args[:contents] && !args[:contents].empty?
            @sentences << Words.gen_sentence(:subject => "You", :action => "see", :target => "boring room")
        end

        if args[:occupants] && !args[:occupants].empty?
            @sentences << Words.gen_sentence(:subject => "You", :action => "see", :target => args[:occupants])
        end

        args[:exits]

        WordState.reset_state
        @sentences.join(" ")
    end

    def self.gen_area_name(args = {})
        name = Sentence::NounPhrase.new(args[:template])
        name.children = [args[:keywords].rand, *name.children] if args[:keywords]
        name.children = ["the", *name.children]
        name.to_s.title
    end

    WordState.reset_state
end