=begin
Grammar in Bushido Mongers uses concepts from phrase structure grammar, generally following constituency relations, but not based on any particular sub-theory.

http://en.wikipedia.org/wiki/Constituent_(linguistics)

PTNodes are the nodes of the tree, with further differentiation between internal nodes (nodes with node children) and
leaf nodes. Internal nodes should not have non-node (i.e. symbol) children, and leaf nodes should not have node
children, but in practice this is not strictly enforced.

The sentence structures have been designed to be as flexible as possible given their current basic nature. For example,
descriptor hashes (see ./game/descriptors) or symbols can be passed in as nouns in any context, and many placements will
also accept pre-created parts of speech (all the PTNode subclasses defined under Sentence). Verb conjugation is
dependent on both abnormal word knowledge and generic rules, which work for most cases.

N.B. Certain word classes have overloaded the base initialize class that just takes children. Those word classes are:
Article and subclasses
Noun and subclasses
Verb
NounPhrase
VerbPhrase
AdjectivePhrase
AdverbPhrase

TODO:
There needs to be some way of representing similar syntactic function - might help for coordinating conjunction determination.
Make coordinators not suck.
Flesh out auxiliaries - right now we just have the basic time tense markers.
http://en.wikipedia.org/wiki/Phraseme
Plurals - lexemes in, need more structural support.
Refactoring preposition associations.
Negatives of nouns, negatives of verbs, negatives of adjectives.
http://en.wikipedia.org/wiki/Nominative_absolute
LOTS BESIDES

=end

require './util/basic'

module Words
    # Each node in the tree is either a root node, a branch node, or a leaf node.
    class PTNode
        # Children in PTInternalNodes are other PTInternalNodes or PTLeafs. Children in PTLeaves are strings.
        attr_reader :children

        def initialize(*children)
            raise(StandardError, "Can't instantiate PTNode class!") if self.class == PTNode
            @children = children.flatten
        end

        def to_s
            if @children.nil?
                Log.warning("PTNode of type #{self.class} has nil children!")
                ''
            else
                @children.join(" ")
            end
        end

        def to_sym
            self.to_s.to_sym
        end
    end

    class PTInternalNode < PTNode
        # Uncomment this to display parens around each parent node.
        # e.g. ((a human) (is ((a biped)))).
#        def to_s
#           "(" + @children.join(" ") + ")"
#        end

        # Uncomment this to display <PartOfSpeech>(children) for each node except Listables.
        # e.g. Sentence(NounPhrase(the, chest), VerbPhrase(is, closed)).
        #def to_s
        #    self.class.to_s.split(/::/).last + "(" + @children.join(", ") + ")"
        #end
    end

    class PTLeaf    < PTNode; end
    class ParseTree < PTInternalNode; end

    # FIXME: Currently only does declarative.
    # Imperative is just implied-receiver, no subject.
    # Questions follow subject-auxiliary inversion
    # http://en.wikipedia.org/wiki/Subject%E2%80%93auxiliary_inversion
    class Clause < ParseTree
        def initialize(db, args)
            to_print = args.dup
            to_print.map { |k,v| v.is_a?(Hash) ? v[:monicker] : v }
            Log.debug(to_print, 7)

            args[:state] ||= State.new

            subject = args[:subject] || args[:agent]

            # active is the default; otherwise, swap the subject/D.O.
            #if args[:state].voice == :passive
            #    subject, args[:target] = args[:target], subject
            #end

            if subject.is_a?(Hash)
                if args[:speaker] && args[:speaker].is_a?(Hash) && subject[:uid] == args[:speaker][:uid]
                    # FIXME: should change based on subjective/objective noun case
                    subject = :i
                elsif args[:observer] && args[:observer].is_a?(Hash) && subject[:uid] == args[:observer][:uid]
                    # FIXME: should change based on subjective/objective noun case
                    subject = :you
                end
            end

            # Subject is i in first person
            if !subject && args[:state].person == :first
                subject = :i
            end

            # First person if subject is :i
            if subject == :i || (Hash === subject && subject[:monicker] == :i)
                args[:state].person = :first
            end

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

            verb = args[:verb] || args[:action] || args[:command]

            # Failing that, try to identify the verb from the :event_type key (:game_event message)
            if verb.nil? && args[:event_type]
                event_mapping = {
                    :unit_killed      => :kill,
                    :object_destroyed => :destroy,
                    :unit_speaks      => :speak,
                    :unit_whispers    => :whisper
                }
                verb = event_mapping[args[:event_type]]
                Log.debug("No verb for event type #{args[:event_type].inspect}!") unless verb
            end

            raise "No verb found from keys #{args.keys.inspect}" unless verb

            # Use an associated verb, if any exist.
            unless [:say].include?(verb)
                synonyms = db.synonyms_of(verb.to_sym)
                if synonyms && synonyms.size > 1
                    verb = args[:verb] = synonyms.rand
                end
            end

            # This ordering only works for active voice, not passive.
            # Really we should make a distinction between patient / direct object
            # and between subject / agent. Right now we hack it in the :target
            # adverbial clause handling.
            # http://en.wikipedia.org/wiki/Patient_(grammar)
            subject = if args[:state].voice == :active
                NounPhrase.new(db, subject, args.merge(:case => :nominative))
            else
                NounPhrase.new(db, subject, args)
            end

            if subject.plural?
                args[:state].plural_person!
            end

            predicate = VerbPhrase.new(db, verb, args)
            @children = [subject, predicate]
        end
    end

    class IndependentClause < Clause
        def sentence; self.to_s.sentence; end
    end

    # http://en.wikipedia.org/wiki/Subordinate_clause
    class DependentClause < Clause
        def initialize(db, args)
            super(db, args)
            @children.insert(0, Subordinator.of_verb?(args[:verb]))
        end
    end

    class Subordinator < PTLeaf
        def self.of_verb?(verb)
            case verb
            when :is, :be
                Subordinator.new(:that)
            when :make
                Subordinator.new(:how)
            else
                Subordinator.new(:that) # ??
            end
        end
    end

    class Sentence < IndependentClause
        def to_s; super.sentence; end
        def sentence; self.to_s; end
    end

    class Question < Sentence
        WH_MEANINGS = {
            :who   => :civil,
            :what  => :object,
            :when  => :event,
            :where => :location,
            :why   => :meaning,
            :how   => :task,
            :if    => :conditional
        }

        def self.question?(pieces)
            pieces.last.to_s.match(/\?$/) ||
            self.wh_word?(pieces.first)
        end

        def self.find_wh_word(pieces)
            pieces.find_index { |p| self.wh_word?(p) }
        end

        def self.wh_words
            WH_MEANINGS.keys
        end

        def self.wh_word?(word)
            self.wh_words.include?(word)
        end

        def to_s
            super.sentence('?')
        end
    end

    class Statement < Sentence
        def self.statement?(pieces)
            # ??
            false
        end
    end

    # Most of the time, we only want to print spaces between words.
    # Nodes include Listable to print commas, spaces, and ands between their children.
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

    # http://en.wikipedia.org/wiki/Relative_clause

    # It will begin with a relative adverb [when, where, or why in English] or a relative pronoun [who, whom, whose,
    # that, or which in English]. However, the English relative pronoun may be omitted and only implied if it plays the
    # role of the object of the verb or object of a preposition in a restrictive clause; for example, He is the boy I
    # saw is equivalent to He is the boy whom I saw, and I saw the boy you are talking about is equivalent to the more
    # formal I saw the boy about whom you are talking.
=begin
(Relative_Pronoun, IC) => pronoun functions as object of verb in IC
(Relative_Adverb,  IC) => outer IC serves as when, where, or why context for IC
(Relative_Pronoun, IC without subject) => pronoun functions as subject of IC
(Relative_Pronoun, IC, Preposition) => pronoun functions as object of preposition
(Preposition, Relative_Pronoun, IC) => pronoun functions as object of preposition
(Possessive_Pronoun)


Relative Pronoun [Functioning as Object of Verb] + Subject + Verb
This is the ball that I was bouncing.
Relative Adverb + Subject + Verb (possibly + Object of Verb)
That is the house where I grew up.
That is the house where I met her.
Relative Pronoun [Functioning as Subject] + Verb (possibly + Object of Verb)
That is the person who hiccuped.
That is the person who saw me.
Relative Pronoun [Functioning as Object of Preposition] + Subject + Verb (possibly + Object of Verb) + Preposition
That is the person who(m) I was talking about.
That is the person who(m) I was telling you about.
Preposition + Relative Pronoun [Functioning as Object of Preposition] + Subject + Verb (possibly + Object of Verb)
That is the person about whom I was talking.
That is the person about whom I was telling you.
Possessive Relative Pronoun + Noun [Functioning as Subject] + Verb (possibly + Object of Verb)
That is the dog whose big brown eyes pleaded for another cookie.
That is the dog whose big brown eyes begged me for another cookie.
Possessive Relative Pronoun + Noun [Functioning as Object of Verb] + Subject + Verb
That is the person whose car I saw.
=end
    class RelativeClause < PTInternalNode
    end

    class Preposition < PTLeaf
        def self.preposition?(db, word)
            db.words_of_type(:preposition).include?(word)
        end
    end

    class PrepositionalPhrase < PTInternalNode
        private
        def new_prep_noun_phrase(db, case_name, args, case_lookup = case_name)
            np = NounPhrase.new(db, args[case_name], args)
            # Determine preposition based on the verb and the case.
            if prep = db.prep_for_verb(args[:verb], case_lookup)
                return Preposition.new(prep), np
            else
                return np
            end
        end
    end

=begin
    # Types: prepositional (during), infinitive (to work hard)
    # adpositions: preposition (by jove), circumpositions (from then on).

    Cases

    The nominative case indicates the subject of a finite verb: We went to the store. => :subject
    The accusative case indicates the direct object of a verb: The clerk remembered us. => :target
    The dative case indicates the indirect object of a verb: The clerk gave us a discount. or The clerk gave a discount to us. => :hasnt_come_up_yet
    The ablative case indicates movement from something, or cause: The victim went from us to see the doctor. and He was unhappy because of depression. => :hasnt_come_up_yet
    The genitive case, which roughly corresponds to English's possessive case and preposition of, indicates the possessor of another noun: John's book was on the table. and The pages of the book turned yellow. => possessor_info?
    The vocative case indicates an addressee: John, are you all right? or simply Hello, John! => :hasnt_come_up_yet
    The locative case (loc) indicates a location: We live in China. => :location
    The lative case (lat) indicates motion to a location. It corresponds to the English prepositions "to" and "into". => :destination
    The instrumental case indicates an object used in performing an action: We wiped the floor with a mop. and Written by hand. => :tool, :material
=end
    class AdverbPhrase < PrepositionalPhrase
        USED_ARGS = [:target, :tool, :destination, :receiver, :components, :success, :statement, :location, :origin]

        # The case_name is the part of the args being used to generate an adverb phrase, and also the third entry in dict/preposition_verb.txt...
        def initialize(db, case_name, args)
            handled = false

            # Based on noun and argument information, decide which preposition to use, if any.
            case case_name
            # TODO - destination preposition s.b. 'into' when moving to indoor locations
            when :target
                if args[:state].voice == :passive
                    # We switch subject & target in passive, so look up how to treat the subject instead.
                    super(new_prep_noun_phrase(db, case_name, args.merge(:case => :nominative), :subject))
                else
                    super(new_prep_noun_phrase(db, case_name, args))
                end
                handled = true
            when :tool, :destination, :location, :origin, :components
                args[:state].add_unique_object(args[case_name]) unless case_name == :components
                super(new_prep_noun_phrase(db, case_name, args))
                handled = true
            when :receiver
                super(new_prep_noun_phrase(db, case_name, args))
                # In Modern English, an indirect object is often expressed
                # with a prepositional phrase of "to" or "for". If there
                # is a direct object, the indirect object can be expressed
                # by an object pronoun placed between the verb and the
                # direct object. For example, "He gave that to me" and
                # "He built a snowman for me" are the same as
                # "He gave me that" and "He built me a snowman".
                handled = true
            when :success
                # Eventually this will be more complex, and describe either
                # how the blow was evaded (parry, blocked, hit armor, etc)
                # or how and where the blow hit.
                if args[case_name]
                    super(:",", :hitting)
                else
                    super(:",", :missing)
                end
            when :statement
                if Array === args[:statement]
                    # It's an array of Symbols; combine 'em.
                    args[:statement] = args[:statement].join(" ")
                end

                super(:",", "\"#{args[:statement]}\"")
            else
                Log.warning("Don't know how to handle argument of type #{type}!")
            end

            # We don't want to generate this again for other verbs and so forth.
            args.delete(case_name) if handled
        end

        def self.new_for_args(db, args)
            (USED_ARGS & args.keys).collect do |arg|
                AdverbPhrase.new(db, arg, args)
            end
        end
    end

    # Four kinds of adjectives:
    # attributive: part of the NP. "happy people". Could be a premodifier (adj) or postmodifier (usually adj phrase)
    # predicative: uses linking copula (usually noun) to attach to noun. "The people are happy."
    # absolute: separate from noun; typically modifies subject or closest noun.
    # nominal: act almost as nouns; when noun is elided or replaces noun; "the meek shall inherit"

    # TODO - handle premodifiers and postmodifiers
    # TODO - handle participles
    class AdjectivePhrase < PrepositionalPhrase
        USED_ARGS = [:subtarget, :location, :of_phrase]

        # The type is the part of the args being used to generate an adverb phrase.
        # args must be defined.
        def initialize(db, type, args)
            case type
            when :subtarget, :location
                args[:state].add_unique_object(args[type])
                super(new_prep_noun_phrase(db, type, args))
            when :of_phrase
                # The preposition is simply :of; no need to look it up.
                super(Preposition.new(:of), NounPhrase.new(db, args[type], args))
            end
        end

        # The hash here expects a :verb entry, which is used for preposition lookups.
        def self.new_for_descriptor(db, descriptor_hash)
            return [] unless Hash === descriptor_hash
            (USED_ARGS & descriptor_hash.keys).collect do |arg|
                AdjectivePhrase.new(db, arg, descriptor_hash)
            end
        end
    end

    class VerbPhrase < PTInternalNode
        include Listable
        # modal auxiliary: will, has
        # modal semi-auxiliary: be going to
        # TODO - add modals based on tense/aspect
        def initialize(db, verbs, args = {:state => State.new})
            verbs = Array(verbs)

            @children = verbs.map do |verb|
                Verb.new(db, verb, args)
            end

            # The non-finite ("verbal") verb forms found in English are infinitives, participles and gerunds.
            # Only generate adverbs for the finite verb.
            unless args[:verb_form] == :infinitive
                args_for_adverb_phrases = args.dup
                args_for_adverb_phrases.merge!(args[:action_hash]) if args[:action_hash]
                args_for_adverb_phrases.merge!(:verb => verbs.last)
                @children += AdverbPhrase.new_for_args(db, args_for_adverb_phrases)
            end

            if args[:complement]
                @children += Array(args[:complement])
            end

            # FIXME - listing won't work while AdverbPhrases are children of VerbPhrase. Add to last V to form second VP?
            @list = (verbs.size > 1)
        end
    end

    # Similar to a substantive clause. (in practice the term is restricted
    # to clauses which represent a nominative or an accusative case; the
    # clauses which stand for an ablative are sometimes called adverbial clauses)

    # Kinds of modifiers: determiners, attributive adjectives, adjective phrases & participial phrases,
    # noun adjuncts, prepositional phrases, relative clauses, other clauses, infinitive phrases.

    # First argument: A list or a single item of either noun barewords or noun hash descriptors.
    # Second argument: Standard args list as created in generators.
    # Stores one of: (Determiner, Noun), (Noun), or (NounPhrase, ..., NounPhrase)
    class NounPhrase < PTInternalNode
        include Listable

        def initialize(db, nouns, args = {})
            # Convert nouns into an array if it isn't already.
            nouns = ArrayEvenAHash(nouns)

            if nouns.all? { |n| n.is_a?(PTNode) }
                # Nouns already created; just attach them.
                super(nouns)
                return
            end

            # Turn every noun into a hash. Descriptors end up with the most information.
            nouns.map! do |noun|
                hash = {}
                case noun
                when Hash
                    # Decompose descriptor hashes into noun name, modifiers, and possession info.
                    if noun[:properties] && noun[:properties][:job] && noun[:monicker] == noun[:type]
                        hash[:monicker] = noun[:properties][:job]
                    elsif noun[:monicker]
                        hash[:monicker] = noun[:monicker]
                    elsif noun[:type]
                        hash[:monicker] = noun[:type]
                    else
                        hash[:monicker] = :thing
                    end

                    unless [String, Symbol].include?(hash[:monicker].class)
                        raise TypeError, "Expected String or Symbol monicker; got (#{hash[:monicker].class}) instead!"
                    end

                    if noun[:count] && noun[:count] > 1
                        hash[:monicker] = Noun.pluralize(hash[:monicker])
                    end

                    hash[:plural]         = (noun[:count] && noun[:count] > 1)
                    hash[:unique]         = noun[:unique] unless noun[:unique].nil?
                    hash[:possessor_info] = noun[:possessor_info] if noun[:possessor_info]
                    hash[:adjectives]     = Adjective.new_for_descriptor(noun)
                    hash[:adj_phrases]    = AdjectivePhrase.new_for_descriptor(db, noun.merge(:verb => args[:verb]))
                    hash[:adj_phrases]   += noun[:properties][:adjective_phrases] if noun[:properties] && noun[:properties][:adjective_phrases]
                when BushidoObjectBase
                    hash[:monicker] = noun.monicker || :thing
                    hash[:type]     = noun.get_type
                    hash[:plural]   = db.words_of_type(:uncountable).include?(noun.monicker.to_sym) || db.words_of_type(:always_plural).include?(noun.monicker.to_sym)
                    hash[:unique]   = (args[:state] && args[:state].unique_object?(noun))
                else
                    hash[:monicker] = noun
                end
                hash
            end

            if @list = @plural = (nouns.size > 1)
                super(
                    nouns.map do |noun|
                        children = generate_children(db, noun)
                        children.size > 1 ? NounPhrase.new(db, children, args) : children.first
                    end
                )
            else
                super(generate_children(db, nouns.first))
            end
        end

        def plural?; @plural; end

        private
        def generate_children(db, noun)
            monicker = noun[:monicker]
            children = []

            if monicker.is_a?(PTNode)
                # Just return the PTNode.
                return [monicker]
            end

            # Turn bare-symbol adjectives into Adjectives
            if noun[:adjectives]
                noun[:adjectives].each do |adj|
                    adj = Adjective.new(adj) unless adj.is_a?(Adjective)
                    children << adj
                end
            end

            children << Noun.new(monicker)

            children += noun[:adj_phrases] if noun[:adj_phrases]

            if !noun[:plural] && determiner = Determiner.new_for_noun(db, noun, children.first, noun[:unique])
                children.insert(0, determiner)
            end

            @plural = noun[:plural] || false

            children
        end
    end

    class Adverb < PTLeaf
    end

    class Adjective < PTLeaf
        def self.new_for_descriptor(descriptor_hash)
            return [] unless Hash === descriptor_hash
            adjectives = []
            # Look for plurality or a specific count.
            if descriptor_hash[:count]
                if (2...10).include?(descriptor_hash[:count])
                    adjectives << descriptor_hash[:count].to_s.to_sym
                elsif descriptor_hash[:count] >= 10
                    adjectives << :many
                elsif descriptor_hash[:count] == 0
                    adjectives << :no
                end
            end
            # Look in the highest layer
            adjectives += Array(descriptor_hash[:adjectives])
            # Look in the properties
            if descriptor_hash[:properties]
                adjectives += Array(descriptor_hash[:properties][:adjectives])
                adjectives += Array(descriptor_hash[:properties][:quality]) if descriptor_hash[:properties][:quality]
            end
            adjectives
        end

        def self.ordinal_adjectives
            {
                1 => [:first,   :"1st"],
                2 => [:second,  :"2nd", :other],
                3 => [:third,   :"3rd"],
                4 => [:fourth,  :"4th"],
                5 => [:fifth,   :"5th"],
                6 => [:sixth,   :"6th"],
                7 => [:seventh, :"7th"],
                8 => [:eighth,  :"8th"],
                9 => [:ninth,   :"9th"]
            }
        end

        def self.ordinal?(word)
            number = ordinal_adjectives.find { |k, v| v.include?(word) }
            Log.debug(number)
            number
        end

        def self.adjective?(db, word)
            ((lexeme = db.get_lexeme(word)) && lexeme.args[:type]) ||
            ordinal_adjectives.any? { |k, v| v.include?(word) }
        end

        def self.rand(db)
            db.words_of_type(:adjective).rand
        end
    end

    # http://en.wikipedia.org/wiki/English_verbs
    # http://en.wikipedia.org/wiki/Predicate_(grammar)
    # http://en.wikipedia.org/wiki/Phrasal_verb
    # http://www.verbix.com/webverbix/English/have.html
    # http://en.wikipedia.org/wiki/Future_tense
    class Verb < PTLeaf
        def initialize(db, verb, args = {})
            case args[:verb_form]
            when :infinitive
                super(:to, verb)
            else
                super(Verb.state_conjugate(db, verb, args[:state]))
            end
        end

        # Used for adding auxiliaries, modals, aspects, etc.
        # List of auxiliaries:
        # be (am, are, is, was, were, being), can, could, dare*, do (does, did),
        # have (has, had, having), may, might, must, need*, ought*, shall, should, will, would
        # TODO - Thus 'shall' is used with the meaning of obligation and 'will' with the meaning of desire or intention.
        def self.state_conjugate(db, verb, state)
            verbs = []
            verbs << :will if state.tense == :future

            case state.aspect
            when :stative
                case state.tense
                when :future
                    [:will, verb]
                else
                    [conjugate(db, verb, state)]
                end
            when :progressive
                raise(StandardError, "Invalid voice #{state.voice}!") unless [:active, :passive].include?(state.voice)

                verbs = []
                verbs << :will if state.tense == :future

                be_state = State.new
                # Do other state fields need copying here?
                be_state.person = state.person
                be_state.tense  = state.tense

                Log.debug(state, 8)
                Log.debug(be_state, 8)

                verbs << conjugate(db, :be, be_state)
                verbs << self.send("#{state.voice}_participle", db, verb)
                verbs
            else
                raise(NotImplementedError, "Aspect #{state.aspect.inspect}")
            end
        end

        # Used for conjugating a single verb.
        # http://en.wikipedia.org/wiki/List_of_English_irregular_verbs
        def self.conjugate(db, infinitive, state)
            if db.conjugation_for?(infinitive, state)
                db.conjugate(infinitive, state)
            else
                Log.debug("#{infinitive} not conjugated for #{state.inspect}", 6)
                db.add_morph(:inflection, state, db.add_lexeme(infinitive)).lemma
            end
        end

        # [One participle], called variously the present, active, imperfect,
        # or progressive participle, is identical in form to the gerund;
        # the term present participle is sometimes used to include the
        # gerund. The term gerund-participle is also used.
        def self.present_participle(db, infinitive)     gerund(db, infinitive); end
        def self.active_participle(db, infinitive)      gerund(db, infinitive); end
        def self.imperfect_participle(db, infinitive)   gerund(db, infinitive); end
        def self.progressive_participle(db, infinitive) gerund(db, infinitive); end
        def self.gerund(db, infinitive)
            _inflection_lookup(db, infinitive, :gerund)
        end

        # [The other participle], called variously the past, passive, or
        # perfect participle, is usually identical to the verb's preterite
        # (past tense) form, though in irregular verbs the two usually differ.
        def self.passive_participle(db, infinitive) past_participle(db, infinitive); end
        def self.perfect_participle(db, infinitive) past_participle(db, infinitive); end
        def self.past_participle(db, infinitive)
            _inflection_lookup(db, infinitive, :past_participle)
        end

        private
        def self._inflection_lookup(db, infinitive, morph_type)
            Log.debug("getting #{morph_type} for #{infinitive}", 8)
            lexeme = db.add_lexeme(infinitive, [:verb, :base])
            participle = lexeme.args[:morphs][morph_type]
            if participle.nil?
                Log.debug("Adding regular #{morph_type} for #{infinitive}", 8)
                participle = db.add_morph(:inflection, morph_type, lexeme)
            end
            participle.lemma
        end
        public

        # However if the base form ends in one of the sibilant sounds
        # (/s/, /z/, /ʃ/, /ʒ/, /tʃ/, /dʒ/), and its spelling does not end in a
        # silent e, then -es is added: buzz → buzzes; catch → catches. Verbs
        # ending in a consonant plus o also typically add -es: veto → vetoes.
        def self.sibilant?(infinitive)
            infinitive = infinitive.to_s if Symbol === infinitive
            infinitive.match(/s$/) ||
            infinitive.match(/[sc]h$/) ||
            (Words::CONSONANTS.include?(infinitive[-2].chr) && infinitive[-1].chr == 'o')
        end

        # Hardcode some basic verbage for now.
        def self.verb?(verb)
            if verb == :is || verb == :are || verb == :be
                return :is
            elsif verb == :make || verb == :made
                return :make
            elsif verb == :find
                return :find
            end
            nil
        end
    end

    # http://en.wikipedia.org/wiki/Genitive_case
    # http://en.wikipedia.org/wiki/Declension#Modern_English
    # he (subjective) and him (objective)
    # who (subjective), and the somewhat archaic whom (objective)
    # Then there are distinct possessive forms such as his and whose.
    # For nouns, possession is shown by the clitic -'s attached to a possessive noun phrase.
    class Noun < PTLeaf
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
        # definite: unique, or specific, or identifiable in a given context.
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

        def self.needs_article?(db, noun)
            !Noun.proper?(noun) &&
            !Noun.pronoun?(noun) &&
            !db.words_of_type(:uncountable).include?(gen_noun_text(noun))
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

        def self.noun?(db, word)
            db.words_of_type(:noun).include?(word) || definite?(word) || pronoun?(word)
        end

        # N.B. There's overlap between certain pronouns and certain possessive determiners.
        def self.pronoun?(noun)
            # If it's e.g. a BushidoObject then it's not a pronoun.
            return false unless noun.respond_to?(:to_sym)
            case noun.to_sym
            # Nominative person pronouns.
            when :I, :i, :you, :he, :she, :ze, :it, :we, :they, :who
                true
            # Possessive pronouns.
            when :mine, :yours, :his, :hers, :zirs, :its, :ours, :theirs
                true
            # Non-nominative person pronouns.
            when :me, :you, :him, :her, :zir, :it, :us, :them, :whom
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

        def self.rand(db)
            db.words_of_type(:noun).rand
        end

        # TODO - use
        def self.plural?(string)
            # Make a simple basic guess.
            string[-1] == 's' || string.match(' and ')
        end

        def self.pluralize(noun)
            # Make a simple basic attempt.
            noun.to_s.gsub(/s?$/, 's')
        end
    end

    # http://en.wikipedia.org/wiki/Pro-form (has table of correlatives)
    # TODO: We'll want to stand in pronouns for certain words (based
    # on previous usage) to avoid repetition. Maybe. Not even DF does this.
    # http://en.wikipedia.org/wiki/Indefinite_pronoun (has table)
    # http://en.wikipedia.org/wiki/Gender-specific_and_gender-neutral_pronouns#Summary (has table)
    class Pronoun < Noun; end

    class PossessivePronoun < Pronoun; end

    class Determiner < PTLeaf
        class << self
            def new_for_noun(db, noun, first_word, unique)
                if Noun.needs_article?(db, noun[:monicker])
                    if noun[:possessor_info] && unique.nil?
                        PossessivePronoun.new(noun[:possessor_info])
                    else
                        # FIXME - determine uniqueness using other adjectives
                        Article.new(noun[:monicker], first_word, unique)
                    end
                else
                    nil
                end
            end
        end
    end

    class PossessiveDeterminer < Determiner
        # Possessive picked based on a) person and b) gender.
        PERSONAL =
        {
            :first         => :my,
            :first_plural  => :our,
            :second        => :your,
            :second_plural => :your,
            :third_plural  => :their
        }
        THIRD_PERSON_GENDER =
        {
            :male       => :his,
            :female     => :her,
            :neutral    => :zir,
            :inanimate  => :its
        }
        def initialize(possessor_info)
            if possessor_info[:person] == :third
                possessive = THIRD_PERSON_GENDER[possessor_info[:gender]]
            else
                possessive = PERSONAL[possessor_info[:person]]
            end
            super(possessive)
        end

        # N.B. There's overlap between certain pronouns and certain possessive determiners.
        def self.possessive?(det)
            (PERSONAL.values + THIRD_PERSON_GENDER.values).include?(det.to_sym)
        end
    end

    class Article < Determiner
        def initialize(noun, first_word = nil, unique = nil)
            if Article.article?(noun)
                super(noun)
            elsif unique || Noun.definite?(noun)
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
            when :honorable, :honest, :hour, :heir, :herb
                true
            when :union, :united, :unicorn, :used, :one
                false
            else
                !!word.to_s.match(/^[aeiou]/)
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
end
