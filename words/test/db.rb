require './words/words'
require './util/timer'

Log.setup("Main", "family_test")

db = WordParser.load

db.add_family(
    {:noun => "bad", :adverb => "badly", :adjective => "bad"},
    {:noun => :poor, :adverb => :poorly},
    {:noun => "substandard", :adverb => :substandardly}
)

related_groups_for_bad = db.get_related_groups(:bad)
Log.debug(["Related to :bad", related_groups_for_bad.inspect])

related_to_first_relation = db.get_related_groups(related_groups_for_bad.first)
Log.debug(["Related to #{related_groups_for_bad.first}", related_to_first_relation.inspect])

adv = related_to_first_relation.find { |g| g[:adverb] }[:adverb]
Log.debug(["Adverb:", adv])
related_adv = db.get_related_words(adv)
Log.debug(["Related adverbs:", related_adv])

nouns = db.get_keyword_words(:noun, :noun)
Log.debug(["Nouns", nouns])

Log.debug(db.get_related_groups(:inspect))

japanese_names = Words.db.get_keyword_words(:japanese, :name)

Log.debug("Japanese names: #{japanese_names.inspect}")
Log.debug("Character name: #{japanese_names.rand}")

see_synonyms = Words.db.get_related_words(:see)

Log.debug(see_synonyms.inspect)
Log.debug(see_synonyms.rand)

Log.debug(Words.db.get_related_words(:attack).inspect)
