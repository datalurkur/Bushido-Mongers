require './words/words'

Log.setup("Main", "family_test")

db = WordParser.load

#packed = WordDB.pack(db)
#db = WordDB.unpack(packed)

db.associate([:bad, :fail, :miserable, :poor, :flailing, :blind, :clumsy, :substandard], [:adjective, :descriptive])
Log.debug(db.associated_words_of(:bad))

packed = WordDB.pack(db)
db = WordDB.unpack(packed)

associated_lexemes = db.associated_lexemes_of(:bad)
Log.debug(["Related to :bad", associated_lexemes.inspect])

other_associated_lexemes = db.associated_lexemes_of(associated_lexemes.first.lemma)
Log.debug(["Related to #{other_associated_lexemes.first.inspect}", other_associated_lexemes.inspect])

related_adv = db.get_associations_by_type(associated_lexemes.first.lemma, :adverb)
Log.debug(["Related adverbs:", related_adv])

nouns = db.words_of_type(:noun)
Log.debug(["Nouns", nouns.select { rand(10) == 0 }])

Log.debug(db.associated_verbs(:inspect))

japanese_names = db.words_of_type(:japanese)

Log.debug("Japanese names: #{japanese_names.inspect}")
Log.debug("Character name: #{japanese_names.rand}")

see_synonyms = db.associated_verbs(:see)

Log.debug(see_synonyms.inspect)
Log.debug(see_synonyms.rand)

Log.debug(db.associated_verbs(:attack).inspect)
