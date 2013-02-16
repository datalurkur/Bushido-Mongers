module Words
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
                raise(StandardError, "'#{verb}' has too many command synonyms: #{matching_commands.inspect}")
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
            # TODO - march through, detecting adjectives or adjective phrases, until we hit a noun.
            pieces.slice!(index,2).last
        end
    end
end