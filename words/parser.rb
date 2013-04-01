require './words/db'
require './util/timer'

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
        db = WordDB.new

        Words::TYPES.each do |type|
            load_files(dict_dir, "#{type}s_*.txt", /^.*#{type}s_(.*).txt/).each do |keyword, lines|
                lines.map(&:chomp).each { |l| db.add_keyword_family(keyword, type => l) }
            end
        end

        load_files(dict_dir, "associations_*.txt", /^.*associations_(.*).txt/).each do |pos, lines|
            lines.each do |line|
                families = line.split(/\s+/).map(&:to_sym).collect { |word| {pos => word} }
                db.add_family(*families)
            end
        end

        # nil corresponds to no preposition; i.e. usually the direct object
        load_files(dict_dir, "preposition_base.txt").each do |match, lines|
            lines.each do |line|
                words = line.split(/\s+/).map(&:to_sym)
                raise "Specifier '#{words.inspect}' should be 2 words!" unless words.size == 2
                preposition, case_name = words
                preposition = nil if preposition == :nil
                db.add_verb_preposition(:default, preposition, case_name)
                db.add_family(:preposition => preposition) if preposition
            end
        end

=begin
        load_files(dict_dir, "preposition_noun.txt").each do |match, lines|
            lines.each do |line|
                words = line.split(/\s+/).map(&:to_sym)
                raise "Specifier '#{words.inspect}' should be 3 words!" unless words.size == 3
                verb, preposition, case_name = words
                preposition = nil if preposition == :nil
                db.add_verb_preposition(verb, preposition, case_name)
                db.add_family(:preposition => preposition) if preposition
            end
        end
=end
        load_files(dict_dir, "preposition_verb.txt").each do |match, lines|
            lines.each do |line|
                words = line.split(/\s+/).map(&:to_sym)
                raise "Specifier '#{words.inspect}' should be 3 words!" unless words.size == 3
                verb, preposition, case_name = words
                preposition = nil if preposition == :nil
                db.add_verb_preposition(verb, preposition, case_name)
                db.add_family(:preposition => preposition) if preposition
            end
        end

        load_files(dict_dir, "conjugations.txt").each do |match, lines|
            lines.each do |line|
                words = line.split(/\s+/)
                infinitive = words.shift.to_sym

                # add infinitive as a verb
                db.add_family(:verb => infinitive)

                # Convert properties ("present,second") into a State
                properties = words.shift.split(",").map(&:to_sym)
                state = Words::State.new(*properties)

                db.add_conjugation_by_person(infinitive, state, words.map(&:to_sym))
            end
        end

        Words.register_db(db)

        db
    end

    # Read (mostly type) information from the raws database.
    # Expects certain raw classes as commands, nouns, etc.
    # Can only happen on the server side.
    def self.read_raws(db, raws_db)
        Log.debug("Reading raws")
        add_raws(db, raws_db, :command,   :verb,      "commands")
        add_raws(db, raws_db, :item,      :noun,      "item types")
        add_raws(db, raws_db, :archetype, :noun,      "NPC types")
        add_raws(db, raws_db, :material,  :adjective, "materials")
    end

    private
    def self.add_raws(db, raws_db, type, pos, desc)
        raws_db.types_of(type).each do |raw|
            db.add_keyword_family(type, pos => raw)
        end
        Log.debug("Found #{db.get_keyword_groups(type).size} #{desc}.")
    end
end
