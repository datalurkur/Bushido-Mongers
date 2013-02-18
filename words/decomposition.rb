module Words
    # Decompose a given command into pieces usable by the command.rb object-finder.
    # TODO - Since this exclusively happens on the server-side, we will have access
    # to adjective and noun information, and can store adjectives and pass them along
    # to the object-finder to narrow the search.
    # parameter: A whitespace-separated list of words.
    def self.decompose_command(entire_command)
        pieces = entire_command.strip.split(/\s+/).collect(&:to_sym)

        # Find the command/verb
        verb = pieces.slice!(0)

        return_hash = {:verb => verb}

        # TODO - Join any conjunctions together
        # The tricky part in real NLP is finding out which kind of conjunction,
        # it is, but for now we will assume it's a noun conjunction.
        #while (i = pieces.index(:and))
        #    first_part = (i > 1)               ? pieces[0...(i-1)] : []
        #    last_part  = (i < pieces.size - 2) ? pieces[(i+1)..-1] : []
        #    first_part + [pieces[(i-1)..(i+1)]] + last_part
        #end

        # Strip out articles, since they aren't necessary (always?)
        pieces = pieces.select { |p| !Sentence::Article.article?(p) }

        # Look for matching command.
        commands = self.db.get_keyword_words(:command, :verb)
        if commands.include?(verb)
            command = verb
        else
            related = self.db.get_related_words(verb)
            if related.nil?
                # Non-existent command; let the playing state handle it.
                return return_hash
            end
            matching_commands = commands & related
            case matching_commands.size
            when 0
                # Non-existent command; let the playing state handle it.
                return return_hash
            when 1
                command = matching_commands.first
            else
                raise(StandardError, "'#{verb}' has too many command synonyms: #{matching_commands.inspect}")
            end
        end
        return_hash[:command] = command

        phrase_args = decompose_phrases(return_hash, verb, pieces)

        if pieces.size > 0
            Log.debug(["Ignoring potentially important syntactic pieces", pieces])
        end

        return_hash.merge!(phrase_args)
        Log.debug(return_hash, 6)
        return_hash
    end

    private

    # N.B. modifies its arguments
    def self.decompose_phrases(return_hash, verb, pieces)
        list = {
            :with  => :tool,
            :at    => :location,
            :using => :materials,
            self.db.get_preposition(verb, :accusative) => :target
        }
        list.each do |prep, value|
            return_hash[value] = decompose_phrase(pieces, prep)
        end

        # Whatever is left over is the target
        return_hash[:target] = pieces.slice!(0) unless return_hash[:target]

        return_hash
    end

    # TODO - add adjective detection and passthroughs, so one could e.g. say "with the big sword"
    # N.B. modifies the pieces array
    def self.decompose_phrase(pieces, preposition)
        if (index = pieces.index(preposition))
            # TODO - march through, detecting adjectives or adjective phrases, until we hit a noun.
            pieces.slice!(index,2).last
        end
    end
end