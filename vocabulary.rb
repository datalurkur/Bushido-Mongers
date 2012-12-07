require 'util/basic'
require 'util/formatting'
require 'set'

VOCAB_DEBUG = 0
$vocab_dir = 'vocabulary'

module Words
    TYPES = :noun, :verb, :adjective, :adverb

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
            results = results.map.send(input[:wordtype])
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

            @noun = hash[:noun].to_sym if hash[:noun]
            @verb = hash[:verb].to_sym if hash[:verb]
            @adjective = hash[:adjective].to_sym if hash[:adjective]
            @adverb = hash[:adverb].to_sym if hash[:adverb]
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
                if families.size > 1
                    raise NameError, "#{hash[type]} already defined in #{families.size} families: #{families.inspect}!"
                end
                puts "#{hash[type]} already defined in #{families.size} families: #{families.inspect}!" if VOCAB_DEBUG > 0
                old_wf = families.first
                if hash[:keywords] && old_wf.keywords != hash[:keywords]
                    old_wf.keywords += hash[:keywords].map(&:to_sym)
                    old_wf.keywords.flatten
                    puts "Added keywords #{hash[:keywords]} to #{old_wf.inspect}" if VOCAB_DEBUG > 0
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

    # The de-facto Words initializer.
    def self.load()
        @families ||= []
        Words::TYPES.each do |type|
            Dir.glob("#{$vocab_dir}/#{type}s_*.txt").each do |file|
                puts "Reading #{file}" if VOCAB_DEBUG > 0
                keyword = file.match(/^.*#{type}s_(.*).txt/)[1].to_sym
                File.readlines(file).each do |line|
                    self.add_family(type => line.chomp, :keywords => [keyword])
                end
            end
        end
        Dir.glob("#{$vocab_dir}/synonyms_*.txt").each do |file|
            puts "Reading #{file}" if VOCAB_DEBUG > 0
            wordtype = file.match(/^.*synonyms_(.*).txt/)[1]
            File.readlines(file).each do |line|
                # Add all the words as word-families, then associate them all.
                families = []
                line.split(/\s/).each do |w|
                    families << self.add_family(wordtype.to_sym => w)
                end
                synonymify(families)
            end
        end
        Dir.glob("#{$vocab_dir}/groups_*.txt").each do |file|
            puts "Reading #{file}" if VOCAB_DEBUG > 0
            type = file.match(/^.*groups_(.*).txt/)[1]
            File.readlines(file).each do |line|
                list = line.split(/\s/)
                # Add-as-adjective for now.
                text = list.pop
                self.add_family(:adjective => text, :generate_from_adj => true, :keywords => list.map(&:to_sym))
            end
        end
    end

    #:keywords=>[], :contents=>[], :occupants=>["Test NPC 23683", "Test NPC 35550", "Test Character"], :exits=>[:west], :name=>"b00"

    class AreaDescription
        def initialize(props = {})
            @sentences = []

            if props[:keywords].empty?
                @sentences << Sentence.new(:subject => "You", :action => "see", :target => "boring room")
            else
                @sentences << Sentence.new(:subject => "You", :action => "see", :target => "boring room", :detail => props[:keywords].rand)
            end

            if !props[:contents].empty?
                @sentences << Sentence.new(:subject => "You", :action => "see", :target => "boring room")
            end

            if !props[:occupants].empty?
                @sentences << Sentence.new(:subject => "You", :action => "see", :target => props[:occupants])
            end
        end

        def to_s
            @sentences.map(&:to_s).join(" ")
        end
    end

    class Sentence
        class SentencePart < String
            # Descriptors can be either adjectives or adverbs attached to the part.
            # The subparts should always be strings.
            attr_accessor :descriptors, :phrases, :plural

            def initialize(str)
                super(str.to_s || '')
                @descriptors = []
                @phrases = []
                @plural = false
            end

            def full
                start = ''
                # catch article
                main = if m = self.match(/^(the) (.*)/)
                    start = m[1]
                    m[2]
                else
                    self.pluralize
                end
                [start, @descriptors, main, @phrases].flatten.reject { |s| s.to_s.empty? }.join(" ")
            end

            def plural?
                return true if @plural
                # Otherwise, make a nasty first-guess.
                self[-1] == 's' || self.match(' and ')
            end

            def pluralize
                # Make a nasty first-approximation.
                if (plural? && noun?) || (!plural? && verb?)
                    self.gsub!(/s?$/, 's')
                end
                self
            end

            def verb?() false; end
            def noun?() false; end
        end

        class Verb < SentencePart
            def verb?() true; end
        end

        class Noun < SentencePart
            def initialize(str)
                if Array === str
                    pop = str.pop
                    super(str.join(", ") + " and " + str[-1])
                elsif str.respond_to?(:name)
                    super(rand(2) == 0 ? "the #{str.class.to_s.downcase}" : str.name)
                else
                    super(str)
                end
            end

            def noun?() true; end
        end

        def initialize(descriptor, synonym = nil)
            @tense = :present
            @features = []

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
            verb_syns = Words.find(:text => @verb).first.synonyms.map(&:verb)
            @verb     = Verb.new(verb_syns.rand) if rand(2) == 0

            @verb.plural = true if @subject.plural?

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
#            (@features.include?(:expletive) ? "There #{@subject.plural? ? "are" : "is"}" : '') +
            ([@subject, @verb, @dir_obj, @ind_obj].map(&:full).join(" ") + '.').sentence
        end
    end

private
    # Unify all the Word.synonyms entries.
    def self.synonymify(*families)
        families.flatten!
        puts "synonymify: #{families.inspect}" if VOCAB_DEBUG > 1

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

class Action
    # {:agent => <Ninja, :name => "Kenji Scrimshank">, :target => <Goat, :name => "Billy Goat Balrog">, :verb => :attack, :tool => :agent_current_weapon}
    def self.do(descriptor = {})
        self.send(descriptor[:action], descriptor)
    end

    def self.attack(descriptor)
        success_roll = rand(20) + 1
        keyword = case success_roll
        when 1..5;   :fail
        when 6..10;  :miss
        when 11..15; :neutral
        when 16..20; :good
        end

        puts Words::Sentence.new(descriptor, keyword)
    end
end

Words.load

if $0 == __FILE__
    require 'util/log'
    Log.setup("Vocabulary Test", "wordtest")
    require 'game/npc'
    class Ninja < NPC; end
    class Goat  < NPC; end
    agent = Ninja.new("Kenji Scrimshank")
    target = Goat.new("Billy Goat Balrog")
    5.times do
        Action.do(:agent => agent, :target => target, :action => :attack)
    end
end
