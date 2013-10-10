require './util/log'
require './util/basic'

Log.setup("Vocabulary Test", "wordtest")

require './words/words'
require './test/fake'

# We want the raws in the words db, which setting up a core accomplishes.
$core = FakeCore.new

db = $core.words_db

# Generate ALL the derivations!
pos_mapping =
{
	:noun      => Words::Noun,
	:verb      => Words::Verb,
	:adverb    => Words::Adverb,
	:adjective => Words::Adjective
}

Lexicon::Derivation::PATTERNS.each do |pattern|
	Log.debug(pattern)
	ot = Lexicon::Derivation.original_type(pattern)
	mt = Lexicon::Derivation.morphed_type(pattern)

	original_class = pos_mapping[ot]
	 morphed_class = pos_mapping[mt]

	all_ot = db.lexemes_of_type(ot)

	all_ot.each do |lexeme|
		#Log.debug("Adding #{lexeme.lemma} derivation based on #{pattern}")
		unless lexeme.args[:derivation] || (lexeme.args[:derivations] && lexeme.args[:derivations][pattern])
			d = db.add_morph(:derivation, pattern, lexeme)
			Log.debug(d.lemma)
		end
	end
end
