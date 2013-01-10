require 'words/family'

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

def load_file(dir, glob_str, regex = //, &block)
    Dir.glob("#{dir}/#{glob_str}").each do |file|
        Log.debug("Reading #{file}")
        match = file.match(regex)

        File.readlines(file).each do |line|
            block.call(line, match)
        end
    end
end

module WordParser
    # The de-facto Words initializer.
    def self.load(dict_dir = 'words/dict')
        raise "Cannot find #{dict_dir}" unless File.exists?(dict_dir) && File.directory?(dict_dir)
        db = WordDB.new

        Words::TYPES.each do |type|
            load_file(dict_dir, "#{type}s_*.txt", /^.*#{type}s_(.*).txt/) do |line, match|
                keyword = match[1].to_sym

                db.add_keyword_family(keyword, {type => line.chomp})
            end
        end
        load_file(dict_dir, "associations_*.txt", /^.*associations_(.*).txt/) do |line, match|
            part_of_speech = match[1].to_sym
            family = line.split(/\s/).collect { |word| {part_of_speech => word} }
            db.add_family(*family)
        end

        load_file(dict_dir, "direct_prepositions.txt") do |line, match|
            words = line.split(/\s/)
            preposition = words.shift
            family = words.collect { |word| {:verb => word} }
            db.add_preposition(preposition, *family)
        end

        Words.register_db(db)
        db
    end

    # Read (mostly type) information from the raws database.
    # Expects certain raw classes as commands, nouns, etc.
    def self.read_raws(db, raws_db)
        raws_db.types_of(:command).each do |comm|
            db.add_keyword_family(:command, {:verb => comm})
        end
        Log.debug("Found #{db.get_keyword_groups(:command).size} commands.")
        raws_db.types_of(:item).each do |item|
            db.add_keyword_family(:item, {:noun => item})
        end
        Log.debug("Found #{db.get_keyword_groups(:item).size} items.")
    end
end