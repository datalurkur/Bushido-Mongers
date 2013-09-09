require './words/structure.rb'

module Words
    # Decompose a given command into pieces usable by the command.rb object-finder.
    # TODO - Since this exclusively happens on the server-side, we will have access
    # to adjective and noun information, and can store adjectives and pass them along
    # to the object-finder to narrow the search.
    # parameter: A whitespace-separated list of words in string format.
    def self.decompose_command(entire_command)
        Log.debug(["Command text entered: #{entire_command.inspect}"], 1)

        # handle the special case of command style: 'this is text that i'm speaking, indicated by the initial quote.
        if entire_command[0].chr == "'"
            args = {:verb => :say, :command => :say, :statement => entire_command[1..-1]}
            return decompose_statement(args, entire_command[1..-1].split_to_sym)
        end

        pieces = entire_command.downcase.split_to_sym

        # Find the command/verb
        verb = pieces.slice!(0)

        args = {:verb => verb, :command => verb}

        # Strip out articles, since they aren't necessary yet.
        # TODO - use possessives to narrow down the search space.
        pieces = pieces.select { |p| !Article.article?(p) }

        # Look for matching command.
        commands = self.db.words_of_type(:command)
        unless commands.include?(verb)
            related = self.db.get_related_words(verb) || []
            matching_commands = commands & related
            if matching_commands.size > 1
                raise(StandardError, "'#{verb}' has too many command synonyms: #{matching_commands.inspect}")
            elsif matching_commands.size == 1
                args[:command] = matching_commands.first
            end
        end

        # Commands involving statements need to be parsed differently.
        if [:say, :whisper, :yell].include?(args[:command])
            regular_case_pieces = entire_command.split_to_sym[1..-1]
            return decompose_statement(args, regular_case_pieces)
        end

        phrase_args = decompose_phrases(args, pieces)

        if pieces.size > 0
            Log.debug(["Ignoring potentially important syntactic pieces", pieces])
        end

        args.merge!(phrase_args)
        Log.debug(args, 6)
        args
    end

    def self.decompose_ambiguous(statement)
        statement = case statement
        when String, Symbol
            statement.to_s.downcase.split_to_sym
        when Array
            statement.map(&:to_s).map(&:downcase).map(&:to_sym)
        else
            Log.error("Don't know how to handle input of type #{statement.class}")
        end

        args = {}

        if Question.question?(statement)
            # Is it a question? Make a query path that can be asked of the knowledge extension.
            # We have no further need of the question mark.
            statement[-1] = statement.last.to_s.chomp('?').to_sym
            Log.debug("Question: #{statement.join(" ")}", 6)
            args = decompose_question(args, statement)
        elsif Statement.statement?(statement)
            # TODO: Decompose the statement and store in memory (if it's believed!)
        end

        args
    end

    private
    def self.decompose_question(args, pieces)
        args[:query] = true
        find_and_delete(args, pieces, 0, [:do, :you, :know])
        if index = Question.find_wh_word(pieces)
            args[:query_lookup] = Question::WH_MEANINGS[pieces.delete_at(index)]
            # These can affect more complex constructions, but just ignore them for now.
            find_and_delete(args, pieces, index, [:do, :i])
            find_and_delete(args, pieces, index, [:can, :i])
        end
        verb = find_verb_phrase(0, pieces)
        args[:connector] = verb

        if noun = find_noun_phrase(0, pieces)
            set_case(:thing, args, *noun)

            possessive = nil
            if noun.last.any? { |adj| possessive = adj if PossessiveDeterminer.possessive?(adj) }
                noun.last.delete(possessive)
                # Swap the positionality of first person/second person. This should maybe be somewhere else?
                if possessive == :your
                    Log.warn("Overriding connector #{args[:connector]}") unless args[:connector] == :is
                    args[:property] = args[:thing]
                    args[:thing] = :self
                end
            end
            is_has_mapping = [:name]
            if is_has_mapping.include?(args[:property])
                args[:connector] = :have
            end
        end

        args
    end

    # Used for deleting unused (so far) phrases to help/hack decomposition.
    def self.find_and_delete(args, pieces, index, phrase)
        orig_pieces = pieces.dup
        Log.debug([args, pieces, index, phrase], 7)
        if pieces[index..(index+phrase.size-1)].zip(phrase).all? { |a, b| a == b }
            pieces.slice!(index, phrase.size)
        end
        Log.debug("#{__method__} changed #{orig_pieces.inspect} to #{pieces.inspect}", 6) if pieces != orig_pieces
    end

    # N.B. modifies the pieces array
    def self.decompose_statement(args, pieces)
        # Look for a :to to be followed by a single noun.
        # No adjective trickery here, because we don't fundamentally know
        # what'll decompose into a noun here and we don't want to snarf any of
        # the statement.
        if pieces.first == :to
            pieces.slice!(0)
            args[:receiver] = pieces.slice!(0)
        end

        # What remains is the statement.
        args[:statement] = pieces

        Log.debug(args, 6)
        args
    end

    # N.B. modifies the pieces array
    def self.decompose_phrases(args, pieces)
        # The default case is what case of the sentence a noun with no preposition serves as.
        default_case = Words.db.get_default_case_for_verb(args[:verb])
        Log.debug("Testing #{default_case} with nil", 6)
        if default_case && noun = find_noun_phrase(0, pieces)
            set_case(default_case, args, noun.first, noun.last)
        end

        prep_map = Words.db.get_prep_map_for_verb(args[:verb])
        prep_map.each_pair do |case_name, preposition|
            Log.debug("Testing #{case_name} with #{preposition.inspect}", 9)
            find_prep_phrase(case_name, preposition, pieces, args)
        end

        args
    end

    private
    def self.set_case(case_name, args, noun, adjs)
        case_name_adjs = (case_name.to_s + "_adjs").to_sym
        Log.debug("Setting #{case_name.inspect} and #{case_name_adjs.inspect} to #{noun.inspect} and #{adjs.inspect}", 6)
        args[case_name] = noun.downcase
        args[case_name_adjs] = adjs.map(&:downcase) unless adjs.empty?
    end

    # N.B. modifies the pieces array
    def self.find_prep_phrase(case_name, preposition, pieces, args)
        if (index = pieces.index(preposition))
            Log.debug("Detected '#{preposition}' at #{index}", 6)
            pieces.slice!(index, 1)
            if noun = find_noun_phrase(index, pieces)
                set_case(case_name, args, noun.first, noun.last)
            end
        end
    end

    # N.B. modifies the pieces array
    def self.find_verb_phrase(index, pieces)
        return nil if index >= pieces.size

        set_snarfback = false
        pieces[index..-1].each_with_index do |piece, i|
            if verb = Verb.verb?(piece)
                if set_snarfback
                    # delete the :to as well
                    pieces.slice!(i - 1, 2)
                else
                    pieces.slice!(i, 1)
                end
                return verb
            end
            set_snarfback = (piece == :to)
        end
        return nil
    end

    # N.B. modifies the pieces array
    def self.find_noun_phrase(index, pieces)
        return nil if index >= pieces.size

        adjectives = []
        noun = nil
        size = 0

        # TODO - Join any conjunctions together
        # The tricky part in real NLP is finding out which kind of conjunction,
        # it is, but for now we should assume it's a noun conjunction.
        #while (i = pieces.index(:and))
        #    first_part = (i > 1)               ? pieces[0...(i-1)] : []
        #    last_part  = (i < pieces.size - 2) ? pieces[(i+1)..-1] : []
        #    first_part + [pieces[(i-1)..(i+1)]] + last_part
        #end
        pieces[index..-1].each_with_index do |piece, i|
            Log.debug([piece, i], 4)
            if Noun.noun?(piece) || # It's an in-game noun.
               (index + i) == pieces.size - 1     || # It's at the end of the index.
               Preposition.preposition?(pieces[index + i + 1]) # Or there's a preposition next.
                Log.debug("found noun #{piece}", 6)
                if noun
                    # It must be an adjective, instead.
                    adjectives << noun
                end
                noun = piece
                size += 1
            elsif Adjective.adjective?(piece)
                Log.debug("found adjective #{piece}", 6)
                adjectives << piece
                size += 1
            elsif PossessiveDeterminer.possessive?(piece)
                Log.debug("found possessive determiner #{piece}", 6)
                adjectives << piece
                size += 1
            elsif Preposition.preposition?(piece)
                # Moving on...
                break
            else
                Log.debug("invalid piece #{piece}", 6)
            end
        end
        pieces.slice!(index, size).last

        return noun ? [noun, adjectives] : nil
    end
end
