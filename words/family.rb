require 'util/log'

class WordDB
    def initialize
        @groups       = []
        @associations = {}
        @keywords     = {}
    end

    def add_family(*list_of_words)
        Log.debug("Adding family #{list_of_words.inspect}", 6)
        list_of_groups = list_of_words.collect do |word|
            if Symbol === word
                find_group_for(word)
            else
                # Check if a definition exists
                if matched = find_group_for(word, false)
                    matched
                else
                    @groups << WordGroup.new(word)
                    @groups.last
                end
            end
        end

        list_of_groups.each do |group|
            to_associate = list_of_groups - [group]
            # Add associations for this reference
            @associations[group] ||= []
            @associations[group].concat(list_of_groups - [group])
        end
    end

    def add_keyword_family(keyword, *list_of_words)
        Log.debug("Adding keyword family #{keyword}, #{list_of_words.inspect}", 6)
        list_of_groups = add_family(*list_of_words)

        @keywords[keyword] ||= []
        @keywords[keyword].concat(list_of_groups)
    end

    # Get a list of related groups
    def get_related_groups(word_or_group)
        group = find_group_for(word_or_group)
        @associations[group]
    end

    # Get a list of related words with the same part of speech as the query word
    def get_related_words(word)
        group = find_group_for(word)
        pos = group.part_of_speech(word)
        @associations[group].select { |g| g.has?(pos) }.collect { |g| g[pos] }
    end

    # Get a list of groups attached to the keyword
    def get_keyword_groups(keyword)
        @keywords[keyword]
    end

    def get_keyword_words(keyword, pos)
        get_keyword_groups(keyword).select { |g| g.has?(pos) }.collect { |g| g[pos] }
    end

    private
    def find_group_for(word, fail_on_nil=true)
        case word
        when Symbol,String
            matching = @groups.select { |group| group.contains?(word.to_sym) }
            Log.debug("Warning - #{word} appears in more than one word group") if matching.size > 1
            raise "No reference to #{word} found in #{self.class}" if matching.size <= 0 && fail_on_nil
            matching.first
        when WordGroup, Hash
            matching = @groups.select { |group| group == word.to_sym }
            raise "Duplicate word groups found in #{self.class} for #{word.inspect}" unless matching.size < 2
            raise "No word group #{word.inspect} found in #{self.class}" if matching.size <= 0 && fail_on_nil
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
