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

=end

def load_file(dir, glob_str, regex, &block)
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
    def self.load(dict_dir)
        Words::TYPES.each do |type|
            load_file(dict_dir, "#{type}s_*.txt", /^.*#{type}s_(.*).txt/) do |line, match|
                keyword = match[1].to_sym
                Words.add_family(type => line.chomp, :keywords => [keyword])
            end
        end
        load_file(dict_dir, "associations_*.txt", /^.*associations_(.*).txt/) do |line, match|
            wordtype = match[1]

            # Add all the words as word-families, then associate them all.
            families = []
            line.split(/\s/).each { |w| families << Words.add_family(wordtype.to_sym => w) }
            Words.associate(families)
        end
        load_file(dict_dir, "groups_*.txt", /^.*groups_(.*).txt/) do |line, match|
            type = match[1]

            list = line.split(/\s/)
            # Add-as-adjective for now.
            text = list.pop
            Words.add_family(:adjective => text, :generate_from_adj => true, :keywords => list.map(&:to_sym))
        end
    end
end