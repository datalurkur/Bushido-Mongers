require './words/db'

=begin

NOUNS, VERBS, NAMES, ADJECTIVES, ADVERBS
===================
File format: nouns_<keyword>.txt
Line Format: <word>

ASSOCIATIONS
===========================
File format: associations_<keyword>.txt
Line Format: [<association>]*

CONJUGATIONS
===========================
File format: conjugations.txt
Line Format: <infinitive> <tense> <first person> <second person> <third sing> <third plural> <first plural>
I you he we you they

=end

module WordParser
    private
    def self.load_files(dir, glob_str, regex = /(.*)/)
        files = {}
        Dir.glob("#{dir}/#{glob_str}").each_with_index do |file, i|
            if match = file.match(regex)
                match = match[1].to_sym
            else
                match = i
            end

            files[match] = File.readlines(file)
        end
        files
    end

    public
    # The de-facto Words initializer.
    def self.load(dict_dir = './words/dict')
        raise(ArgumentError, "Cannot find #{dict_dir}.") unless File.exists?(dict_dir) && File.directory?(dict_dir)

        db = nil
        time_block("Words loaded") do
            db = WordDB.new

            time_block("Word types parsed") do
                Words::TYPES.each do |type|
                    load_files(dict_dir, "#{type}s_*.txt", /^.*#{type}s_(.*).txt/).each do |keyword, lines|
                        lines.map(&:chomp).each { |l| db.add_keyword_family([type, keyword], type => l) }
                    end
                end
            end

            time_block("Word associations parsed") do
                load_files(dict_dir, "associations_*.txt", /^.*associations_(.*).txt/).each do |pos, lines|
                    lines.each do |line|
                        families = line.split(/\s+/).map(&:to_sym).collect { |word| {pos => word} }
                        db.add_family(*families)
                    end
                end
            end

            time_block("Prepositions parsed") do
                load_files(dict_dir, "prepositions_*.txt", /^.*prepositions_(.*).txt/).each do |prep_case, lines|
                    lines.each do |line|
                        words = line.split(/\s+/).map(&:to_sym)
                        preposition = words.shift
                        db.add_keyword_family(prep_case, :preposition => preposition)
                        words.each do |word|
                            db.add_preposition(preposition, word)
                        end
                    end
                end
            end

            time_block("Conjugations parsed") do
                load_files(dict_dir, "conjugations.txt").each do |match, lines|
                    lines.each do |line|
                        words = line.split(/\s+/)
                        infinitive = words.shift.to_sym

                        # add infinitive as a verb
                        db.add_family(:verb => infinitive)

                        # Convert properties ("present,second") into a State
                        properties = words.shift.split(",").map(&:to_sym)
                        state = Words::State.new(properties)

                        db.add_conjugation_by_person(infinitive, state, words.map(&:to_sym))
                    end
                end
            end

            Words.register_db(db)
        end

        db
    end

    # Read (mostly type) information from the raws database.
    # Expects certain raw classes as commands, nouns, etc.
    # Can only happen on the server side.
    def self.read_raws(db, raws_db)
        Log.debug("Reading raws")

        raws_db.types_of(:command).each do |comm|
            db.add_keyword_family(:command, :verb => comm)
        end
        Log.debug("Found #{db.get_keyword_groups(:command).size} commands.")

        raws_db.types_of(:item).each do |item|
            db.add_keyword_family([:noun, :item], :noun => item)
        end
        Log.debug("Found #{db.get_keyword_groups(:item).size} item types.")

        raws_db.types_of(:material).each do |mat|
            db.add_keyword_family([:adjective, :material], :adjective => mat)
        end
        Log.debug("Found #{db.get_keyword_groups(:material).size} materials.")
    end
end
