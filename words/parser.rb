require './words/db'
require './util/timer'

=begin

Read in from the dictionary:
* Lists of basic word forms.
* Lists of associated words (e.g. speak and say, or dog and dogs).
* Lists of prepositions for given prepositional 'adverb' phrases.
* Allomorphic conjugations.
* Allomorphic exceptions to common rules (e.g. where dog/dogs is the regular case, ox/oxen is an irregular type)

http://en.wikipedia.org/wiki/Allomorph

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
    # Returns a hash: {:"first matching regex" => array of arrays of words }
    def self.load_files(dir, glob_str, regex = /(.*)/)
        files = {}
        Dir.glob("#{dir}/#{glob_str}").each_with_index do |file, i|
            if match = file.match(regex)
                match = match[1].to_sym
            else
                raise LoadError, "No match #{regex.inspect} for #{file}?"
            end

            list = File.readlines(file).map { |l| l.split(/\s+/).map(&:to_sym) }
            files[match] = list
        end
        files
    end

    public
    def self.load_dictionary(db, dict_dir)
        raise(ArgumentError, "Cannot find #{dict_dir}.") unless File.exists?(dict_dir) && File.directory?(dict_dir)

        Words::TYPES.each do |type|
            load_files(dict_dir, "#{type}s_*.txt", /^.*#{type}s_(.*).txt/).each do |additional_type, list|
                list.each { |l| l.each { |w| db.add_lexeme(w, [type, additional_type]) } }
            end
        end

        load_files(dict_dir, "associations_*.txt", /^.*associations_(.*).txt/).each do |pos, list|
            list.each do |words|
                db.associate(words, pos)
            end
        end

        # nil corresponds to no preposition; i.e. usually the direct object
        load_files(dict_dir, "preposition_base.txt").each do |match, list|
            list.each do |words|
                raise "Specifier '#{words.inspect}' should be 2 words!" unless words.size == 2
                preposition, case_name = words
                preposition = nil if preposition == :nil
                db.add_verb_preposition(:default, preposition, case_name)
                db.add_lexeme(preposition, :preposition) if preposition
            end
        end

=begin
        load_files(dict_dir, "preposition_noun.txt").each do |match, list|
            list.each do |words|
                raise "Specifier '#{words.inspect}' should be 3 words!" unless words.size == 3
                verb, preposition, case_name = words
                preposition = nil if preposition == :nil
                db.add_verb_preposition(verb, preposition, case_name)
            end
        end
=end
        load_files(dict_dir, "preposition_verb.txt").each do |match, list|
            list.each do |words|
                raise "Specifier '#{words.inspect}' should be 3 words!" unless words.size == 3
                verb, preposition, case_name = words
                preposition = nil if preposition == :nil
                db.add_verb_preposition(verb, preposition, case_name)
                db.add_lexeme(preposition, :preposition) if preposition
            end
        end

        load_files(dict_dir, "conjugations.txt").each do |match, list|
            list.each do |words|
                next if words.empty?
                infinitive = words.shift

                # add infinitive as a verb
                db.add_lexeme(infinitive, :verb)

                # Convert properties ("present,second") into a State
                properties = words.shift.to_s.split(",").map(&:to_sym)
                state = Words::State.new(*properties)

                db.add_conjugation_by_person(infinitive, state, words.map(&:to_sym))
            end
        end

        db
    end

    # Read (mostly type) information from the raws database.
    # Expects certain raw classes as commands, nouns, etc.
    # Can only happen on the server side.
    def self.read_raws(db, raws_db)
        Log.debug("Reading raws")
        add_raws(db, raws_db, :command,      :verb,      "commands",  true)
        add_raws(db, raws_db, :object,       :noun,      "item types")
        add_raws(db, raws_db, :archetype,    :noun,      "NPC types")
        #add_raws(db, raws_db, :raw_material, :adjective, "materials")
    end

    private
    def self.add_raws(db, raws_db, raw_category, word_type, desc, static=false)
        types = static ? raws_db.static_types_of(raw_category) : raws_db.instantiable_types_of(raw_category)
        types.each do |raw_type|
            db.add_lexeme(raw_type, [raw_category, word_type])
        end
        Log.debug("Found #{types.size} #{desc}.")
    end
end
