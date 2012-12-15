require 'util/basic'
require 'util/formatting'
require 'set'
require 'util/log'
require 'words/parser'

module Words
    TYPES = :noun, :name, :verb, :adjective, :adverb

    VOWELS = ['a', 'e', 'i', 'o', 'u']
    CONSONANTS = ('a'..'z').to_a - VOWELS

    # Receives query hash; returns list of matching families or nil
    def self.find(input = {})
        input[:text] = input[:text].to_sym if input[:text] && String === input[:text]

        @families ||= []
        search_families = @families.dup
        results = []

        if input[:keyword]
            search_families = search_families.select { |f| f.keywords && f.keywords.include?(input[:keyword].to_sym) }
        end

        if input[:synonym]
            if String === input[:synonym] || Symbol === input[:synonym]
                input[:synonym] = self.find(:text => input[:synonym].to_sym).first
            end
            search_families = search_families.select { |f| f.synonyms && f.synonyms.include?(input[:synonym]) }
        end

        if input[:text]
            search_families.each do |family|
                if family.find(input[:text])
                    results << family
                end
            end
        else
            results = search_families
        end

        if input[:wordtype]
            results = results.map { |f| f.send(input[:wordtype]) }
        end

        return results.empty? ? nil : results
    end

    def self.proper_nouns
        Words.find(:keyword => :proper).map(&:noun).map(&:to_s)
    end

    class WordFamily
        attr_reader *Words::TYPES
        attr_accessor :keywords, :synonyms

        def initialize(hash)
            @keywords = []
            @synonyms = []

            Words::TYPES.each do |type|
                instance_variable_set("@#{type}", hash[type].to_sym) if hash[type]
            end

            @keywords = hash[:keywords].map(&:to_sym) if hash[:keywords]

            # FIXME: It's confusing that synonyms aren't read here.

            if hash[:generate_from_adj]
                @adverb = Adjective.adv(@adjective).to_sym unless @adverb
                @noun = Adjective.noun(@adjective).to_sym unless @noun
            end
        end

        def list
            @list = [@noun, @verb, @adjective, @adverb].compact.map(&:to_sym)
        end

        def find(text)
            Words::TYPES.each do |type|
                if self.send(type) == text
                    return type
                end
            end
            nil
        end
    end

    def self.add_family(hash)
        @families ||= []

        Words::TYPES.each do |type|
            next unless hash[type]
            if families = Words.find(:text => hash[type])
                Log.debug("#{hash[type]} already defined in #{families.size} families: #{families.inspect}!") if families.size > 1
                old_wf = families.first
                if hash[:keywords] && old_wf.keywords != hash[:keywords]
                    old_wf.keywords += hash[:keywords].map(&:to_sym)
                    old_wf.keywords.flatten
                    Log.debug("Added keywords #{hash[:keywords]} to #{old_wf.inspect}")
                end
                return old_wf
            end
        end

        new_wf = WordFamily.new(hash)
        @families << new_wf
        return new_wf
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

    #:keywords=>[], :contents=>[], :occupants=>["Test NPC 23683", "Test NPC 35550", "Test Character"], :exits=>[:west], :name=>"b00"

    class AreaDescription
        def initialize(props = {})
            @sentences = []

            if props[:keywords].empty?
                @sentences << Sentence.new(:subject => "You", :action => "see", :target => "boring room")
            else
                @sentences << Sentence.new(:subject => "You", :action => "see", :target => (props[:keywords].rand.to_s + " room"))
            end

            if props[:contents] && !props[:contents].empty?
                @sentences << Sentence.new(:subject => "You", :action => "see", :target => "boring room")
            end

            if props[:occupants] && !props[:occupants].empty?
                @sentences << Sentence.new(:subject => "You", :action => "see", :target => props[:occupants])
            end

            props[:exits]
        end

        def to_s
            @sentences.map(&:to_s).join(" ")
        end
    end

    # FIXME: Generate a random name using the keywords
    class AreaName
        def initialize(props = {})
            @name = Sentence::Noun.new(props[:template].to_s)

            @name.descriptors << "the"
            @name.descriptors << props[:keywords].rand if props[:keywords]
        end

        def to_s
            @name.to_s.title
        end
    end

    class Sentence
        # http://en.wikipedia.org/wiki/English_verbs#Syntactic_constructions
        # http://en.wikipedia.org/wiki/English_clause_syntax
        ASPECTS = [:perfect, :imperfect, :habitual, :stative, :progressive]
        MOOD    = [:indicative, :subjunctive, :imperative]

        class SentencePart
            # Descriptors can be either adjectives or adverbs attached to the part.
            # The subparts should always be strings.
            attr_accessor :descriptors, :phrases, :plural

            def initialize(str)
                @main = str.to_s
                @descriptors = []
                @phrases = []
                @plural = false
            end

            def to_s
                start = ''
                main = @main
                # catch article
                if m = main.match(/^(the) (.*)/)
                    start = m[1]
                    main  = m[2]
                end
                [start, @descriptors, main, @phrases].flatten.reject { |s| s.to_s.empty? }.join(" ")
            end

            def plural?
                return true if @plural
                # Otherwise, make a nasty first-guess.
                @main[-1] == 's' || @main.match(' and ')
            end

            def pluralize
                # Make a nasty first-approximation.
                if (plural? && noun?) || (!plural? && verb?)
                    @main.gsub!(/s?$/, 's')
                end
                self
            end

            def verb?() false; end
            def noun?() false; end
        end

        # http://en.wikipedia.org/wiki/English_verbs
        # http://en.wikipedia.org/wiki/List_of_English_irregular_verbs
        # http://en.wikipedia.org/wiki/Predicate_(grammar)
        # http://en.wikipedia.org/wiki/Phrasal_verb
        # Technically, the predicate contains the verb, so this will be expanded upon in the future.
        class Verb < SentencePart
            def initialize(infinitive)
                @infinitive = infinitive.to_s
                super(infinitive)
            end

            def conjugate(tense, subject = :third_singular)
                # Words::Conjugations
                if {}.keys.include?(@infinitive)
                    nil
                end

                case tense
                when :present
                    @main += sibilant? ? 'es' : 's'
                when :past
                    # Double the ending letter, if necessary.
                    @main.gsub!(/([nbpt])$/, '\1\1')
                    # drop any ending 'e'
                    @main.sub!(/e$/, '')
                    @main += 'ed'
                end
                self
            end

            # However if the base form ends in one of the sibilant sounds
            # (/s/, /z/, /ʃ/, /ʒ/, /tʃ/, /dʒ/), and its spelling does not end in a
            # silent e, then -es is added: buzz → buzzes; catch → catches. Verbs
            # ending in a consonant plus o also typically add -es: veto → vetoes.
            def sibilant?
                # First stab.
                @infinitive[-1].chr == 's' ||
                (CONSONANTS.include?(@infinitive[-2].chr) && @infinitive[-1].chr == 'o')
            end

            def verb?() true; end
        end

        # TODO - handle gerunds
        class Noun < SentencePart
            def initialize(str)
                if Array === str
                    if str.size == 1
                        super(str.pop)
                    else
                        pop = str.pop
                        super(str.join(", ") + " and " + pop)
                    end
                elsif str.respond_to?(:name)
                    super(rand(2) == 0 ? "the #{str.class.to_s.downcase}" : str.name)
                else
                    super(str)
                end
            end

            def noun?() true; end
        end

        def initialize(descriptor, synonym=nil)
            Log.debug("Descriptor is #{descriptor.inspect}")
            @tense = descriptor[:tense] || :present # TODO - implement other tenses
            @features = []
            @voice = :active # TODO - implement passive
            @aspect = :stative # TODO - implement aspect

            @features << :expletive if rand(2) == 0

            @subject = if descriptor[:subject]
                descriptor[:subject]
            elsif descriptor[:agent]
                (rand(2) == 0 ? "the #{descriptor[:agent].class.to_s.downcase}" : descriptor[:agent].name)
            end

            @subject = Noun.new(@subject)
            @verb    = Verb.new(descriptor[:verb] || descriptor[:action])
            @dir_obj = Noun.new(descriptor[:target])
            @ind_obj = Noun.new(descriptor[:tool])

            # Synonymify the verb, maybe.
            associated_verb_families = Words.find(:text => @verb.to_s)
            if associated_verb_families && associated_verb_families.size > 1
                verb_syns = associated_verb_families.first.synonyms.map(&:verb)
                Log.debug("verb #{@verb} syns #{verb_syns}", 6)
                if !verb_syns.empty?
                    @verb = Verb.new(verb_syns.rand)
                end
            end

            @verb.conjugate(@tense)

            # action descriptors: The generic ninja generically slices the goat with genericness.
            phrase, adverb = ''
            if synonym && matches = Words.find(:keyword => synonym)
                describer = matches.rand
                @subject.descriptors << describer.adjective
                @verb.descriptors << describer.adverb
                @verb.phrases << "with #{describer.noun}"
            end
        end

        def to_s
#            if @features.include?(:expletive)
#                "There #{@subject.plural? ? "are" : "is"}" : '') +
#                ([@subject, @verb, @dir_obj, @ind_obj].map(&:full).join(" ") + '.').sentence

#            (@features.include?(:expletive) ? "There #{@subject.plural? ? "are" : "is"}" : '') +
            ([@subject, @verb, @dir_obj, @ind_obj].map(&:to_s).join(" ") + '.').sentence
        end
    end

private
    # Unify all the associated entries.
    def self.associate(*families)
        families.flatten!
        Log.debug("associate: #{families.inspect}")

        # Add already-existing synonyms.
        synonyms = families.inject([]) do |list, f|
            list + [f] + [f.synonyms]
        end.flatten!

        families.each do |f|
            f.synonyms = synonyms
        end
        families
    end
end