#!/usr/bin/ruby

require 'util/log'
require 'util/basic'

Log.setup("Vocabulary Test", "wordtest")

require 'words/words'

WordParser.load('words/dict')

class Action
    def self.do(descriptor = {})
        self.send(descriptor[:action], descriptor)
    end

    def self.attack(descriptor)
        success_roll = rand(20) + 1
        keyword = case success_roll
        when 1..5;   :fail
        when 6..10;  :miss
        when 11..15; :neutral
        when 16..20; :good
        end

        puts Words::Sentence.new(descriptor, keyword)
    end
end

Log.debug(Words.find(:keyword => :japanese, :wordtype => :name).inspect)
Log.debug("Character name: #{Words.find(:keyword => :japanese, :wordtype => :name).map(&:to_s).rand}")

wfs = Words.find(:text => "see")
wfs.each do |wf|
    Log.debug(wf.verb)
end
Log.debug(Words.find(:text => "see").rand.verb)

Log.debug(Words::AreaName.new({:template => :mountain, :keywords => [:beautiful]}).to_s)
Log.debug(Words::AreaDescription.new({:template => :mountain, :keywords => [:beautiful], :occupants => ["elderly Beaver", "Frank the Ninja Bunny"]}).to_s)
Log.debug(Words::AreaName.new({:template => :mountain, :keywords => [:beautiful]}).to_s)

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
    Action.do(:agent => agent, :target => target, :action => :attack)
end
