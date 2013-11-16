require './words/words'

Log.setup("Main", "family_test")

db = Lexicon.new

#packed = Lexicon.pack(db)
#db = Lexicon.unpack(packed)

db.associate([:bad, :fail, :miserable, :poor, :flailing, :blind, :clumsy, :substandard], :synonym)
Log.debug(db.associated_words_of(:bad, :synonym))

packed = Lexicon.pack(db)
db = Lexicon.unpack(packed)

associated_lexemes = db.associated_lexemes_of(:bad, :synonym)
Log.debug(["Related to :bad", associated_lexemes.inspect])

other_associated_lexemes = db.associated_lexemes_of(associated_lexemes.first.lemma, :synonym)
Log.debug(["Related to #{other_associated_lexemes.first.inspect}", other_associated_lexemes.inspect])

related_adv = db.get_associations_by_type(associated_lexemes.first.lemma, :synonym, :adverb)
Log.debug(["Related adverbs:", related_adv])

nouns = db.words_of_type(:noun)
Log.debug(["Nouns", nouns.select { rand(10) == 0 }])

[:uncountable, :always_plural].each do |word_type|
	Log.debug(word_type.to_s)
	nouns.each { |n| Log.debug(n) if db.words_of_type(word_type).include?(n) }
end

Log.debug(db.synonyms_of(:inspect))

japanese_names = db.words_of_type(:japanese)

Log.debug("Japanese names: #{japanese_names.inspect}")
Log.debug("Character name: #{japanese_names.rand}")

see_synonyms = db.synonyms_of(:see)

Log.debug(see_synonyms.inspect)
Log.debug(see_synonyms.rand)

Log.debug(db.synonyms_of(:attack).inspect)
Log.debug(db.synonyms_of(:attack).inspect)
