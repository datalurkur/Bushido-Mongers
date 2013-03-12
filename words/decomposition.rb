module Words
    # Decompose a given command into pieces usable by the command.rb object-finder.
    # TODO - Since this exclusively happens on the server-side, we will have access
    # to adjective and noun information, and can store adjectives and pass them along
    # to the object-finder to narrow the search.
    # parameter: A whitespace-separated list of words.
    def self.decompose_command(entire_command)
        Log.debug(["command text entered: #{entire_command.inspect}"], 1)
        pieces = entire_command.downcase.strip.split(/\s+/).collect(&:to_sym)

        # Find the command/verb
        verb = pieces.slice!(0)

        # handle the special case of command style: 'this is text that i'm speaking, indicated by the initial quote.
        if verb.to_s[0].chr == "'"
            args = {:verb => :say, :command => :say}
            return decompose_statement(args, [verb.to_s[1..-1]] + pieces)
        end

        args = {:verb => verb, :command => verb}

        # Strip out articles, since they aren't necessary yet.
        # TODO - use possessives to narrow down the search space.
        pieces = pieces.select { |p| !Sentence::Article.article?(p) }

        # Look for matching command.
        commands = self.db.get_keyword_words(:command, :verb)
        unless commands.include?(verb)
            related = self.db.get_related_words(verb) || []
            matching_commands = commands & related
            if related.empty? || matching_commands.empty?
                # Non-existent command; let the playing state handle it.
                return args
            end

            if matching_commands.size > 1
                raise(StandardError, "'#{verb}' has too many command synonyms: #{matching_commands.inspect}")
            end
            args[:command] = matching_commands.first
        end

        # Commands involving statements need to be parsed differently.
        if [:say, :whisper, :yell].include?(args[:command])
            return decompose_statement(args, pieces)
        end

        phrase_args = decompose_phrases(args, pieces)

        if pieces.size > 0
            Log.debug(["Ignoring potentially important syntactic pieces", pieces])
        end

        args.merge!(phrase_args)
        Log.debug(args, 6)
        args
    end

    private
    # N.B. modifies the pieces array
    def self.decompose_statement(args, pieces)
        # This is tricky. The first word might be the receiver:
        # $ whisper jeff I saw a beaver.
        # $ tell antonio I loved you in Zorro.
        # But it might also just be part of the statement:
        # $ say I saw a beaver.
        # This is probably something that should either be decided in the command logic.
        # I believe for most command words it will be the :target.

        Words.db.get_prep_map_for_verb(args[:verb]).each do |case_name, preposition|
            if pieces.size > 0
                phrase = slice_initial_phrase(preposition, pieces)
                args[case_name] = phrase if phrase
            end
        end

        # What remains is the statement.
        args[:statement] = pieces

        args
    end

    # N.B. modifies the pieces array
    def self.decompose_phrases(args, pieces)
        default_case = Words.db.get_default_case_for_verb(args[:verb])
        Log.debug("Testing #{default_case} with nil", 6)
        if pieces.size > 0 && default_case
            noun = slice_noun_phrase(0, pieces)
            args[default_case] = noun if noun
        end

        prep_map = Words.db.get_prep_map_for_verb(args[:verb])
        prep_map.each_pair do |case_name, preposition|
            Log.debug("Testing #{case_name} with #{preposition.inspect}", 6)
            phrase = slice_prep_phrase(preposition, pieces)
            args[case_name] = phrase if phrase
        end

        args
    end

    # N.B. modifies the pieces array
    def self.slice_initial_phrase(preposition, pieces)
        if (pieces[0] == preposition)
            Log.debug("Detected initial '#{preposition}'", 6)
            pieces.slice!(0, 1)
            noun = slice_noun_phrase(index, pieces)
        end
        Log.debug(noun, 6) if noun
        noun
    end

    # N.B. modifies the pieces array
    def self.slice_prep_phrase(preposition, pieces)
        if (index = pieces.index(preposition))
            Log.debug("Detected '#{preposition}' at #{index}", 6)
            pieces.slice!(index, 1)
            noun = slice_noun_phrase(index, pieces)
        end
        noun
    end

    # N.B. modifies the pieces array
    def self.slice_noun_phrase(index, pieces)
        if index >= pieces.size
            return nil
        end

        adjectives = []
        noun = nil
        size = 0

        pieces[index..-1].each_with_index do |piece, i|
            Log.debug([piece, i], 6)
            Log.debug([pieces[index + i], Words::Sentence::Preposition.preposition?(pieces[index + i])], 6)
            if Words::Sentence::Noun.noun?(piece) ||
                  (index + i) == pieces.size - 1 ||
                  Words::Sentence::Preposition.preposition?(pieces[index + i + 1])
                # TODO - Join any conjunctions together
                # The tricky part in real NLP is finding out which kind of conjunction,
                # it is, but for now we will assume it's a noun conjunction.
                #while (i = pieces.index(:and))
                #    first_part = (i > 1)               ? pieces[0...(i-1)] : []
                #    last_part  = (i < pieces.size - 2) ? pieces[(i+1)..-1] : []
                #    first_part + [pieces[(i-1)..(i+1)]] + last_part
                #end
                Log.debug(["found noun", piece], 6)
                if noun
                    # It must be an adjective, instead.
                    adjectives << noun
                end
                noun = piece
                size += 1
            elsif Words::Sentence::Adjective.adjective?(piece)
                Log.debug(["found adjective", piece], 6)
                adjectives << piece
                size += 1
            else
                Log.debug(["invalid piece", piece], 6)
                break
            end
        end
        pieces.slice!(index, size).last

        return noun ? [noun, adjectives] : nil
    end
end
