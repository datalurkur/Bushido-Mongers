require 'set'
require './util/basic'
require './util/formatting'
require './util/log'
require './words/parser'

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

    # FIXME: use this
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
    # Aspect descriptions: actions that are processes (bhāva), from those where the action is considered as a completed whole (mūrta). This is the key distinction between the imperfective and perfective.
    # further :aspects => [:inchoative,  # starting a state (not really used in English)
    #                      :prospective, # describing an event that occurs subsequent to a given reference time
    #                      :gnomic,      # for aphorisms. Similar to :habitual, doesn't usually use articles.
    #
    # http://en.wikipedia.org/wiki/Subjunctive_mood
    # The form of the subjunctive is distinguishable from the indicative in five circumstances:
    # in the third person singular of any verb in the present form;
    # in all instances of the verb "be" in the present form;
    # in the first and third persons singular of the verb "be" in the past form;
    # in all instances of all verbs in the future form; and
    # in all instances of all verbs in the present negative form.
    class State
        FIELDS = {
            :aspects => [:perfect, :imperfect, :habitual, :stative, :progressive],
            :tense   => [:present, :past, :future],
            :mood    => [:indicative, :subjunctive, :imperative],
            :person  => [:first, :second, :third, :first_plural, :second_plural, :third_plural],
            :voice   => [:active, :passive]
        }

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

        def self.plural_person(person)
            index = FIELDS[:person].index(person)
            case index
            when 0, 1, 2
                FIELDS[:person][ index + 3 ]
            when 3, 4, 5
                person
            else
                raise "Not in State.person field: #{person}"
            end
        end

        def plural_person!
            self.person = State.plural_person(self.person)
        end

        # State is used in WordDB's special conjugation hash.
        def eql?(other)
            case other
            when State
                @aspect == other.aspect &&
                @tense  == other.tense  &&
                @mood   == other.mood   &&
                @person == other.person &&
                @voice  == other.voice
            else
                raise "Can't compare word state to #{other.class}"
            end
        end

        def hash
            [@aspect, @tense, @mood, @person, @voice].hash
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
                # Descriptor composition
                # TODO - parse hash for noun descriptors
                if Hash === nouns
                    nouns = nouns[:monicker]
                end

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
        # http://en.wikipedia.org/wiki/Predicate_(grammar)
        # http://en.wikipedia.org/wiki/Phrasal_verb
        # http://www.verbix.com/webverbix/English/have.html
        class Verb < ParseTree::PTLeaf
            def initialize(verb, args = {})
                state = args[:state]
                @children = Verb.state_conjugate(verb, state)

                # Insert a direct preposition, if it exists for the verb.
                if args[:target]
                    preposition = Words.db.get_preposition(verb)
                    @children << preposition if preposition
                end
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
                        raise "Invalid voice #{state.voice}!"
                    end
                else
                    raise NotImplementedError
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
                    infinitive.gsub!(/([nbpt])$/, '\1\1')
                    # drop any ending 'e'
                    infinitive.sub!(/e$/, '')
                    infinitive += 'ed'
                when :future
                    # Handled in state_conjugate.
                    raise NotImplementedError
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
        args[:state] ||= State.new

        subject = args[:subject] || args[:agent]
        verb    = args[:verb] || args[:action] || args[:command]

        # Subject is you in second person
        if !subject && args[:state].person == :second
            subject = :you
        end

        # Second person if subject is you
        if subject == :you || (Hash === subject && subject[:monicker] == :you)
            args[:state].person = :second
        end

        # If subject is plural and person isn't, adjust the person
        if Array === subject && subject.size > 1
            args[:state].plural_person!
        end

        raise unless verb

        # Use an associated verb, if any exist.
        associated_verbs = Words.db.get_related_words(verb.to_sym)
        if associated_verbs && associated_verbs.size > 1
            verb = associated_verbs.rand
        end

        subject_np = Sentence::NounPhrase.new(subject)
        verb_np    = Sentence::VerbPhrase.new(verb, args)

        Sentence.new(subject_np, verb_np).to_s
    end

    def self.describe_corporeal(target)
        # Describe the corporeal body
        body = target[:properties][:incidental].first
        sentences = [gen_copula(:target=>body[:monicker])]
        sentences << describe_composition(body)

        # TODO - Add more information about abilities, features, etc.
    end

    def self.describe_list(list, verb, target_monicker, state)
        sentences = []
        if list && !list.empty?
            sentences << gen_sentence(
                            :subject => list.collect { |p| p[:monicker] },
                            :verb    => verb,
                            :target  => target_monicker,
                            :state   => state)
            sentences += list.collect do |part|
                if part[:is_type].include?(:composition_root)
                    describe_composition(part)
                else
                    gen_copula(:target => part[:monicker])
                end
            end
        end
        sentences
    end

    def self.describe_composition(target)
        state = State.new
        # Description is a currently-progressing state, so passive progressive.
        state.voice  = :passive
        state.aspect = :progressive

        sentences = []

        sentences << describe_list(target[:properties][:external], :attach, target[:monicker], state)
        sentences << describe_list(target[:properties][:worn],     :wear,   target[:monicker], state)
        sentences << describe_list(target[:properties][:grasped],  :grasp,  target[:monicker], state)

        sentences.flatten.join(" ")
    end

    # TODO - Still not a proper copula.
    def self.gen_copula(args = {})
        unless args[:subject] || args[:agent]
            args[:subject] = :it
        end
        unless args[:verb] || args[:action] || args[:command]
            args[:verb]    = :be
        end

        # TODO - Use expletive / inverted copula construction
        # TODO - expletive more often for second person
#        if Chance.take(:coin_toss)
            # <Agent> <verbs> <target>
            self.gen_sentence(args)
#        else
            # passive: <target> is <verbed> <preposition <Agent>>
#        end
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

        if args[:exits] && !args[:exits].empty?
            @sentences << Words.gen_sentence(args.merge(:target => Sentence::Noun.new("exits to #{Sentence::NounPhrase.new(args[:exits])}")))
        end

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

    # Decompose a given command into pieces usable by the command.rb object-finder.
    # TODO - Since this exclusively happens on the server-side, we will have access
    # to adjective and noun information, and can store adjectives and pass them along
    # to the object-finder to narrow the search.
    # parameter: A whitespace-separated list of words.
    def self.decompose_command(command)
        pieces = command.strip.split(/\s+/).collect(&:to_sym)

        # TODO - Join any conjunctions together
        #while (i = pieces.index(:and))
        #    first_part = (i > 1)               ? pieces[0...(i-1)] : []
        #    last_part  = (i < pieces.size - 2) ? pieces[(i+1)..-1] : []
        #    first_part + [pieces[(i-1)..(i+1)]] + last_part
        #end

        # Strip out articles, since they aren't necessary (always?)
        pieces = pieces.select { |p| !Sentence::Article.article?(p) }

        # Find the verb
        verb = pieces.slice!(0)

        # Look for matching command.
        commands = self.db.get_keyword_words(:command, :verb)
        if commands.include?(verb)
            command = verb
        else
            related = self.db.get_related_words(verb)
            if related.nil?
                # Non-existent command; let the playing state handle it.
                return {:command => verb, :args => {}}
            end
            matching_commands = commands & related
            case matching_commands.size
            when 0
                # Non-existent command; let the playing state handle it.
                return {:command => verb, :args => {}}
            when 1
                command = matching_commands.first
            else
                raise "'#{verb}' has too many command synonyms: #{matching_commands.inspect}"
            end
        end

        # Handle "look at rock" case
        if preposition = self.db.get_preposition(verb)
            target = decompose_phrase(pieces, preposition)
        end

        tool      = decompose_phrase(pieces, :with)
        location  = decompose_phrase(pieces, :at)
        materials = decompose_phrase(pieces, :using)

        # Whatever is left over is the target
        target = pieces.slice!(0) unless target

        if pieces.size > 0
            Log.debug(["Ignoring potentially important syntactic pieces", pieces])
        end

        ret = {
            :command   => command,
            :tool      => tool,
            :location  => location,
            :materials => materials,
            :target    => target
        }
        Log.debug(ret, 6)
        ret
    end

    private
    # TODO - add adjective detection and passthroughs, so one could e.g. say "with the big sword"
    # Note that this method modifies the pieces array
    def self.decompose_phrase(pieces, preposition)
        if (index = pieces.index(preposition))
            pieces.slice!(index,2).last
        end
    end
end
