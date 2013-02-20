module Words
    # Decompose a given command into pieces usable by the command.rb object-finder.
    # TODO - Since this exclusively happens on the server-side, we will have access
    # to adjective and noun information, and can store adjectives and pass them along
    # to the object-finder to narrow the search.
    # parameter: A whitespace-separated list of words.
    def self.decompose_command(entire_command)
        Log.debug(["entire_command: #{entire_command.inspect}"], 6)
        pieces = entire_command.strip.split(/\s+/).collect(&:to_sym)

        # Find the command/verb
        verb = pieces.slice!(0)

        args = {:verb => verb}

        # Strip out articles, since they aren't necessary yet.
        # TODO - use possessives to narrow down the search space.
        pieces = pieces.select { |p| !Sentence::Article.article?(p) }

        # Look for matching command.
        commands = self.db.get_keyword_words(:command, :verb)
        if commands.include?(verb)
            command = verb
        else
            related = self.db.get_related_words(verb)
            if related.nil?
                # Non-existent command; let the playing state handle it.
                return args.merge(:command => verb)
            end
            matching_commands = commands & related
            case matching_commands.size
            when 0
                # Non-existent command; let the playing state handle it.
                return args.merge(:command => verb)
            when 1
                command = matching_commands.first
            else
                raise(StandardError, "'#{verb}' has too many command synonyms: #{matching_commands.inspect}")
            end
        end
        args[:command] = command

        phrase_args = decompose_phrases(args, pieces)

        if pieces.size > 0
            Log.debug(["Ignoring potentially important syntactic pieces", pieces])
        end

        args.merge!(phrase_args)
        Log.debug(args, 6)
        args
    end

    private

    # N.B. modifies its arguments
    # Next iteration: Store in form
    # verb => [[preposition, case], [preposition, case], ...]
    def self.decompose_phrases(args, pieces)
        ({
            :instrumental => :tool,
            :lative       => :destination,
            :locative     => :location,
            :accusative   => :target
        }.map do |prep_case, value|
            prep = Words.db.get_preposition(args[:verb], prep_case) || Words.db.default_prep_for_case(prep_case)
            Log.debug([prep, value], 8)
            [prep, value]
        end + [:using, :materials]).each do |prep, value|
            args[value] = slice_prep_phrase(prep, pieces)
        end

        # D.O. is often preposition-less, so what remains is the target.
        # TODO - Store exceptions in dictionary?
        case args[:verb]
        when :move, :go, :travel, :walk
            args[:destination] = slice_noun_phrase(0, pieces) unless args[:destination]
        else
            args[:target] = slice_noun_phrase(0, pieces) unless args[:target]
        end

        args
    end

    # TODO - add adjective detection and passthroughs, so one could e.g. say "with the big sword"
    # N.B. modifies the pieces array
    def self.slice_prep_phrase(preposition, pieces)
        Log.debug([pieces, preposition], 5)
        if (index = pieces.index(preposition))
            noun = slice_noun_phrase(index + 1, pieces)
        end
        Log.debug(noun, 6) if noun
        noun
    end

    def self.slice_noun_phrase(index, pieces)
        Log.debug([index, pieces])
        if index >= pieces.size
            return nil
        end

        adjectives = []
        noun = nil
        size = 0

        pieces[index..-1].each do |piece|
            if Words::Sentence::Adjective.adjective?(piece)
                Log.debug(["found adjective", piece])
                adjectives << piece
                size += 1
            elsif Words::Sentence::Noun.noun?(piece)
                # TODO - Join any conjunctions together
                # The tricky part in real NLP is finding out which kind of conjunction,
                # it is, but for now we will assume it's a noun conjunction.
                #while (i = pieces.index(:and))
                #    first_part = (i > 1)               ? pieces[0...(i-1)] : []
                #    last_part  = (i < pieces.size - 2) ? pieces[(i+1)..-1] : []
                #    first_part + [pieces[(i-1)..(i+1)]] + last_part
                #end
                Log.debug(["found noun", piece])
                noun = piece
                size += 1
            else
                Log.debug(["invalid piece", piece])
                break
            end
        end
        pieces.slice!(index, size).last

#        [noun, adjectives]
        noun
    end
end
