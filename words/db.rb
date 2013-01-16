require './util/log'

class WordDB
    def initialize
        @groups       = []
        @associations = {}
        @keywords     = {}
        @prepositions = {}
        @conjugations = {}
    end

    def collect_groups(*list_of_words)
        list_of_words.collect do |word|
            if Symbol === word
                find_group_for(word)
            else
                # Check if a definition exists
                if matched = find_group_for(word, false)
                    matched
                elsif mergee = find_group_matching_any(word, false)
                    merge(mergee, word)
                else
                    @groups << WordGroup.new(word)
                    @groups.last
                end
            end
        end
    end

    def find_group_matching_any(word, verbose=true)
        case word
        when Symbol,String
            # should've been caught by find_group_for already
            nil
        when WordGroup
            # Necessary? Ideally. But not implemented yet.
            raise NotImplementedError
        when Hash
            matching = @groups.select do |group|
#                Log.debug(["Analyzing:", word, group])
                word.any? { |pos, w| group.has?(pos) && group[pos] == w }
            end
            raise "Duplicate word groups found in #{self.class} for #{word.inspect}" unless matching.size < 2
            Log.debug("No word group '#{word.inspect}' found!") if matching.size <= 0 && verbose
            matching.first
        else
            Log.debug("Couldn't find group matching word class #{word.class}")
        end
    end

    # requirements: matched is a WordGroup, word is a Hash
    def merge(mergee, merger)
        Log.debug(["Merging:", mergee, merger])
        merger.each { |k, v| mergee[k] = v }
    end

    def associate_groups(*list_of_groups)
        list_of_groups.each do |group|
            to_associate = list_of_groups - [group]
            # Add associations for this reference
            @associations[group] ||= []
            @associations[group].concat(list_of_groups - [group])
        end
    end

    def add_family(*list_of_words)
        Log.debug("Adding family #{list_of_words.inspect}", 6)
        list_of_groups = collect_groups(*list_of_words)
        associate_groups(*list_of_groups)
    end

    def add_keyword_family(keyword, *list_of_words)
        Log.debug("Adding keyword family #{keyword}, #{list_of_words.inspect}", 6)
        list_of_groups = add_family(*list_of_words)

        @keywords[keyword] ||= []
        @keywords[keyword].concat(list_of_groups)
    end

    # Similar to add_keyword_family, but associate_groups is not called, because
    # we don't want all associated groups to be connected to the preposition as well.
    def add_preposition(preposition, *list_of_words)
        Log.debug("Adding preposition family #{preposition}, #{list_of_words.inspect}", 6)
        list_of_groups = collect_groups(*list_of_words)

        @prepositions[preposition] ||= []
        @prepositions[preposition].concat(list_of_groups)
    end

    # Get a list of related groups
    def get_related_groups(word_or_group)
        group = find_group_for(word_or_group)
        return nil if group.nil?
        @associations[group]
    end

    # Get a list of related words with the same part of speech as the query word
    def get_related_words(word)
        group = find_group_for(word)
        return nil if group.nil?
        pos = group.part_of_speech(word)
        @associations[group].select { |g| g.has?(pos) }.collect { |g| g[pos] }
    end

    # Get a list of groups attached to the keyword
    def get_keyword_groups(keyword)
        @keywords[keyword]
    end

    def get_keyword_words(keyword, pos)
        keyword_groups = get_keyword_groups(keyword)
        if keyword_groups.nil? || keyword_groups.empty?
            Log.warning(["No keyword groups found for #{keyword.inspect}", @keywords])
            return []
        end
        keyword_groups.select { |g| g.has?(pos) }.collect { |g| g[pos] }
    end

    # Check whether a word is associated with a preposition
    def get_preposition(word)
        @prepositions.each do |prep, list_of_groups|
            list_of_groups.each do |group|
                if group.contains?(word)
                    return prep
                end
            end
        end
        nil
    end

    # For 'special' conjugations. Basic rules are in Sentence::Verb::conjugate.
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
        case list.size
        when 2, 3, 6
            Words::State::FIELDS[:person].each do |person|
                curr_state = state.dup
                curr_state.person = person

                expr = list.shift
                if expr
                    add_conjugation(infinitive, state, expr)
                else
                    # If the list is unfilled, use the first person as default.
                    add_conjugation(infinitive, state, first_person)
                end
            end
        else
            raise "Wrong number of conjugation terms: #{list}"
        end
    end

    private
    def find_group_for(word, verbose = true)
        case word
        when Symbol,String
            matching = @groups.select { |group| group.contains?(word.to_sym) }
            Log.debug("Warning - '#{word}' appears in more than one word group") if matching.size > 1
            Log.debug("No reference to '#{word}' found!") if matching.size <= 0 && verbose
            matching.first
        when WordGroup, Hash
            matching = @groups.select { |group| group == word.to_sym }
            raise "Duplicate word groups found in #{self.class} for #{word.inspect}" unless matching.size < 2
            Log.debug("No word group '#{word.inspect}' found!") if matching.size <= 0 && verbose
            matching.first
        else
            raise "Can't find groups given type #{word.class}"
        end
    end
end

class WordGroup
    def initialize(args={})
        @parts_of_speech = args.to_sym
    end

    # Values should all be converted to symbols already
    def to_sym
        self
    end

    def [](part_of_speech)
        parts_of_speech[part_of_speech]
    end

    def []=(part_of_speech, word)
        parts_of_speech[part_of_speech] = word
    end

    def part_of_speech(word)
        raise "#{word} is not a member of #{parts_of_speech.inspect}" unless contains?(word)
        parts_of_speech.find { |k,v| v == word }.first
    end

    def has?(part_of_speech)
        parts_of_speech.has_key?(part_of_speech)
    end

    def contains?(word)
        parts_of_speech.values.include?(word)
    end

    def ==(other)
        case other
        when WordGroup
            parts_of_speech == other.parts_of_speech
        when Hash
            parts_of_speech == other
        else
            raise "Can't compare wordgroup to #{other.class}"
        end
    end

    protected
    attr_reader :parts_of_speech
end
