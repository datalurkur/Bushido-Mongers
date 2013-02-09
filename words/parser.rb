require './words/db'

=begin

NOUNS, VERBS, NAMES, ADJECTIVES, ADVERBS
===================
File format: nouns_<keyword>.txt
Line Format: <keyword>

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

def load_files(dir, glob_str, regex = //, &block)
    Dir.glob("#{dir}/#{glob_str}").each do |file|
        Log.debug("Reading #{file}", 7)
        match = file.match(regex)

        File.readlines(file).each do |line|
            block.call(line, match)
        end
    end
end

module WordParser
    # The de-facto Words initializer.
    def self.load(dict_dir = './words/dict')
        raise(ArgumentError, "Cannot find #{dict_dir}.") unless File.exists?(dict_dir) && File.directory?(dict_dir)
        db = WordDB.new

        Words::TYPES.each do |type|
            load_files(dict_dir, "#{type}s_*.txt", /^.*#{type}s_(.*).txt/) do |line, match|
                keyword = match[1].to_sym

                db.add_keyword_family(keyword, {type => line.chomp})
            end
        end

        load_files(dict_dir, "associations_*.txt", /^.*associations_(.*).txt/) do |line, match|
            part_of_speech = match[1].to_sym
            family = line.split(/\s+/).collect { |word| {part_of_speech => word} }
            db.add_family(*family)
        end

        # TODO - Add distinctions between preposition types, i.e. store match somewhere.
        load_files(dict_dir, "prepositions_*.txt", /^.*prepositions_(.*).txt/) do |line, match|
            words = line.split(/\s+/).map(&:to_sym)
            preposition = words.shift
            prep_type = match[1].to_sym
            Log.debug([preposition, prep_type, words])
            words.each do |verb|
                # add infinitive as a verb
                family = {:verb => verb}
                db.add_family(family)
                db.add_preposition(preposition, prep_type, family)
            end
        end

        load_files(dict_dir, "conjugations.txt") do |line, match|
            words = line.split(/\s+/)
            infinitive = words.shift.to_sym

            # add infinitive as a verb
            db.add_family(:verb => infinitive)

            # Convert properties ("present,second") into a State
            properties = words.shift.split(",").map(&:to_sym)
            state = Words::State.new
            properties.each do |prop|
                Words::State::FIELDS.each do |field, list|
                    if list.include?(prop)
                        state.send("#{field}=", prop)
                    end
                end
            end

            db.add_conjugation_by_person(infinitive, state, words.map(&:to_sym))
        end

        db.instance_exec {
            Log.debug(@conjugations, 8)
        }

        Words.register_db(db)
        db
    end

    # Read (mostly type) information from the raws database.
    # Expects certain raw classes as commands, nouns, etc.
    # Can only happen on the server side.
    def self.read_raws(db, raws_db)
        raws_db.types_of(:command).each do |comm|
            db.add_keyword_family(:command, {:verb => comm})
        end
        Log.debug("Found #{db.get_keyword_groups(:command).size} commands.")

        raws_db.types_of(:item).each do |item|
            db.add_keyword_family(:item, {:noun => item})
        end
        Log.debug("Found #{db.get_keyword_groups(:item).size} item types.")

        raws_db.types_of(:material).each do |mat|
            db.add_keyword_family(:material, {:adjective => mat})
        end
        Log.debug("Found #{db.get_keyword_groups(:material).size} materials.")
    end
end
