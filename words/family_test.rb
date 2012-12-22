#!/usr/bin/ruby

require 'words/words'

Log.setup("Main thread", "family_test")

db = WordParser.load

=begin
db.add_family(
    {:noun => "bad", :adverb => "badly"},
    {:noun => :poor, :adverb => :poorly},
    {:noun => "substandard", :adverb => :substandardly}
)
=end

related_groups_for_bad = db.get_related_groups(:bad)
Log.debug(["Related to :bad", related_groups_for_bad])

related_to_first_relation = db.get_related_groups(related_groups_for_bad.first)
Log.debug(["Related to #{related_groups_for_bad.first}", related_to_first_relation])

adv = related_to_first_relation.first[:adverb]
Log.debug("Adverb: #{adv}")
related_adv = db.get_related_words(adv)
Log.debug(["Related adverbs:", related_adv])

nouns = db.get_related_groups(:noun)
Log.debug(["Related to :noun", nouns])
