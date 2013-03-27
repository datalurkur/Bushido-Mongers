require './util/log'
require './util/basic'

Log.setup("Vocabulary Test", "wordtest")

require './words/words'

Log.debug(Words.gen_area_name({:type => :mountain, :keywords => [:beautiful]}))
Log.debug(Words.gen_area_name({:type => :sewer,    :keywords => [:dank]}))
Log.debug(
    Words.describe_room(
        :command => :inspect,
        :agent  => :you,
        :target =>
        {
            :type       => :room,
            :monicker   => :mountain,
            :adjectives => [:tall, :broken],
            :objects    => ["elderly beaver", "Frank the Ninja Bunny"],
            :exits      => [:east, :north]
        }
    )
)

def john_and_mary(state)
    Log.debug(Words.gen_sentence(:agent => :John, :command => :move, :destination => :west, :state=>state))
    Log.debug(Words.gen_sentence(:agent => :John, :action  => :see,  :target      => :Mary, :state=>state))
end

s = Words::State.new
s.tense = :future
john_and_mary(s)
s.tense = :present
john_and_mary(s)
s.tense = :past
john_and_mary(s)

Log.debug(Words.gen_copula)
Log.debug(Words.gen_copula(:adjectives=>:sunny))

Log.debug(
    Words.gen_sentence(
        :subject => [:Billy_Bob, :beaver],
        :verb    => :walk,
        :destination => :bar
    )
)

# Action tests.
require './raws/db'
require './test/fake'
$core = CoreWrapper.new
require './game/descriptors'

def db_create(db, test_npc_type, name)
    $core.create(test_npc_type, :position => FakeRoom.new, :name => name)
end

require './game/character_loader'
observer = $core.create_agent(:human, true, {:name => "Kenji Skrimshank", :position => FakeRoom.new})
agent = Descriptor::BushidoObjectDescriptor.describe(observer, observer)
Log.debug(Words.describe_body(agent))
target = db_create($core.db, :goat, "Billy Goat Balrog")
target = Descriptor::BushidoObjectDescriptor.describe(target, observer)
Log.debug(Words.describe_body(target))

# {:agent => <Ninja, :name => "Kenji Scrimshank">, :target => <Goat, :name => "Billy Goat Balrog">, :verb => :attack, :tool => :agent_current_weapon}
puts Words.describe_attack(:attacker => agent, :defender => target, :command => :attack, :tool => :dagger, :result_hash => {:damage_type => :piercing})
puts Words.describe_attack(:defender => agent, :attacker => target, :command => :attack,                   :result_hash => {:damage_type => [:piercing, :blunt, :nonlethal].rand})

target = db_create($core.db, :chest, "Bosom")
target = Descriptor::BushidoObjectDescriptor.describe(target, observer)
Log.debug(Words.describe_container_class(target))
