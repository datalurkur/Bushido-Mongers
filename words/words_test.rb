#!/usr/bin/ruby

require 'util/log'
require 'util/basic'

Log.setup("Vocabulary Test", "wordtest")

require 'words/words'

db = WordParser.load

class Action
    def self.do(descriptor = {})
        self.send(descriptor[:action], descriptor)
    end

    def self.attack(descriptor)
        success_roll = rand(20) + 1
        descriptor[:result] = case success_roll
        when 1..10;  :miss
        when 11..20; :hit
        end

        puts Words.gen_sentence(descriptor)
    end
end


japanese_names = db.get_keyword_words(:japanese, :name)

Log.debug("Japanese names: #{japanese_names.inspect}")
Log.debug("Character name: #{japanese_names.rand}")

see_synonyms = db.get_related_words(:see)

Log.debug(see_synonyms.inspect)
Log.debug(see_synonyms.rand)

Log.debug(db.get_related_words(:attack).inspect)

Log.debug(Words.gen_area_name({:template => :mountain, :keywords => [:beautiful]}).to_s)
Log.debug(Words.gen_room_description({:template => :mountain, :keywords => [:beautiful], :occupants => ["elderly beaver", "Frank the Ninja Bunny"]}).to_s)

Log.debug(Words.gen_sentence(:agent => :John, :action => :see, :target => :Mary).to_s)

Log.debug(Words::Sentence::NounPhrase.new(:dagger).to_s)


class NPC
    attr_reader :name
    def initialize(name) @name = name; end
end
class Ninja < NPC; end
class Goat  < NPC; end

agent = Ninja.new("Kenji Scrimshank")
target = Goat.new("Billy Goat Balrog")
# {:agent => <Ninja, :name => "Kenji Scrimshank">, :target => <Goat, :name => "Billy Goat Balrog">, :verb => :attack, :tool => :agent_current_weapon}
5.times do
    Action.do(:agent => agent, :target => target, :action => :attack, :tool => :dagger)
end
