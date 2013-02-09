require './util/log'
require './util/basic'

Log.setup("Vocabulary Test", "wordtest")

require './words/words'

japanese_names = Words.db.get_keyword_words(:japanese, :name)

Log.debug("Japanese names: #{japanese_names.inspect}")
Log.debug("Character name: #{japanese_names.rand}")

see_synonyms = Words.db.get_related_words(:see)

Log.debug(see_synonyms.inspect)
Log.debug(see_synonyms.rand)

Log.debug(Words.db.get_related_words(:attack).inspect)

Log.debug(Words.gen_area_name({:type => :mountain, :keywords => [:beautiful]}))
Log.debug(Words.gen_area_name({:type => :sewer,    :keywords => [:dank]}))
Log.debug(Words.gen_room_description(:zone => :mountain, :keywords => [:beautiful], :objects => ["elderly beaver", "Frank the Ninja Bunny"], :exits => [:east, :north]))


def john_and_mary(state)
    Log.debug(Words.gen_sentence(:agent => :John, :target => :west, :command => :move, :state=>state))
    Log.debug(Words.gen_sentence(:agent => :John, :action => :see,  :target  => :Mary, :state=>state))
end

s = Words::State.new
s.tense = :future
john_and_mary(s)
s = Words::State.new
john_and_mary(s)
s.tense = :past
john_and_mary(s)

Log.debug(Words.gen_copula)
Log.debug(Words.gen_copula(:adjective=>:sunny))

Log.debug(
    Words.gen_sentence(
        :subject => [:Billy_Bob, :beaver],
        :verb    => :walk,
        :target  => :bar
    )
)

# Action tests.
require './raws/db'
db = ObjectDB.get('default')
require './test/fake'
$core = FakeCore.new(db)
require './game/descriptors'

def test_npc(db, test_npc_type, name)
    db.create($core, test_npc_type, :position => FakeRoom.new, :name => name)
end

class Action
    def self.do(args = {})
        self.send(args[:action], args)
    end

    def self.attack(args)
        success_roll = rand(20) + 1
        args[:result] = case success_roll
        when 1..10;  :miss
        when 11..20; :hit
        end

        Log.debug(Words.gen_sentence(args))
    end
end

observer = test_npc(db, :character, "Kenji Skrimshank")
agent = Descriptor::BushidoObjectDescriptor.describe(observer, observer)
Log.debug(Words.describe_corporeal(agent))
target = test_npc(db, :goat, "Billy Goat Balrog")
target = Descriptor::BushidoObjectDescriptor.describe(target, observer)
Log.debug(Words.describe_corporeal(target))

# {:agent => <Ninja, :name => "Kenji Scrimshank">, :target => <Goat, :name => "Billy Goat Balrog">, :verb => :attack, :tool => :agent_current_weapon}
5.times do
    Action.do(:agent => agent, :target => target, :action => :attack, :tool => :dagger)
end