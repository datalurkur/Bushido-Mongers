# Some rump definitions that don't fit anywhere else.
module Words
    # Used for dictionary lookups.
    TYPES = :noun, :name, :verb, :adjective, :adverb

    VOWELS = ['a', 'e', 'i', 'o', 'u']
    CONSONANTS = ('a'..'z').to_a - VOWELS

    def self.register_db(db)
        @db = db
    end

    def self.db
        if @db
            @db
        else
            WordParser.load
        end
    end
end

=begin
# FIXME: use this
class Adjective
    def self.adv(adj)
        adv = adj.to_s if Symbol === adj
        adv = adv.gsub(/le$/, '').
                  gsub(/ic$/, 'ical').
                  gsub(/y$/, 'i')
        "#{adv}ly"
    end

    def self.noun(adj)
        noun = adj.to_s if Symbol === adj
        noun = noun.gsub(/y$/, 'i')
        "#{noun}ness"
    end
end
=end