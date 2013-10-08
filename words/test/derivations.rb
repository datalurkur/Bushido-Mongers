require './util/log'
require './util/basic'

Log.setup("Vocabulary Test", "wordtest")

require './words/words'
require './test/fake'

# We want the raws in the words db, which setting up a core accomplishes.
$core = FakeCore.new

$db = WordDB.new

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
	dt = Lexicon::Derivation.derived_type(pattern)

	original_class = pos_mapping[ot]
	 derived_class = pos_mapping[dt]

	all_oc = $db.lexemes_of_type(ot)

	all_oc.each do |lexeme|
		#Log.debug("Adding #{lexeme.lemma} derivation based on #{pattern}")
		d = $db.add_derivation(Lexicon::Derivation.new(pattern, lexeme))
		Log.debug(d.lemma)
	end
end