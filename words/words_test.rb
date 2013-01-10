#!/usr/bin/ruby

require 'util/log'
require 'util/basic'

Log.setup("Vocabulary Test", "wordtest")

require 'words/words'

#require 'raws/db'
#require 'game/object_extensions'
#require 'game/game_core'
#core = GameCore.new
#core.setup(:world_size => 1, :world_depth => 1)

japanese_names = Words.db.get_keyword_words(:japanese, :name)

Log.debug("Japanese names: #{japanese_names.inspect}")
Log.debug("Character name: #{japanese_names.rand}")

see_synonyms = Words.db.get_related_words(:see)

Log.debug(see_synonyms.inspect)
Log.debug(see_synonyms.rand)

Log.debug(Words.db.get_related_words(:attack).inspect)

Log.debug(Words.gen_area_name({:type => :mountain, :keywords => [:beautiful]}).to_s)
Log.debug(Words.gen_area_name({:type => :sewer,    :keywords => [:dank]}).to_s)
Log.debug(Words.gen_room_description(:type => :mountain, :keywords => [:beautiful], :objects => ["elderly beaver", "Frank the Ninja Bunny"], :exits => [:east, :north]).to_s)

Log.debug(Words.gen_sentence(:agent => :John, :target=>:west, :command=>:move).to_s)
Log.debug(Words.gen_sentence(:agent => :John, :action => :see, :target => :Mary).to_s)

begin # Action tests.
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
end
