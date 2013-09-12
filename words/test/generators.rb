require './util/log'
require './util/basic'

Log.setup("Vocabulary Test", "wordtest")

require './words/words'
require './test/fake'

$core = FakeCore.new

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
Log.debug(Words.gen_copula(:complement => :sunny))

Log.debug(
    Words.gen_sentence(
        :subject => [:Billy_Bob, :beaver],
        :verb    => :walk,
        :destination => :bar
    )
)

Log.debug(
    Words.gen_sentence(
        :receiver => :human,
        :statement => "Man is a miserable little pile of secrets.",
        :response_needed => nil,
        :verb => :speak,
        :agent => :human,
        :event_type => :unit_says
    )
)

# Action tests.
require './raws/db'
require './test/fake'
require './game/descriptors'

observer = $core.create_npc(:human, :name => "Kenji Skrimshank", :position => $core.create(FakeRoom))
agent = Descriptor.describe(observer, observer)
Log.debug(Words.describe_body(agent))
# Test missing parts.
kenji_leg = observer.get_contents(:external).find { |bp| bp.get_type == :leg }
observer.component_destroyed(kenji_leg, :external, observer)
Log.debug(Words.describe_body(Descriptor.describe(observer, observer)))
kenji_leg = observer.get_contents(:external).find { |bp| bp.get_type == :leg }
observer.component_destroyed(kenji_leg, :external, observer)
Log.debug(Words.describe_body(Descriptor.describe(observer, observer)))

target = $core.create(:goat, {:position => $core.create(FakeRoom), :name => "Billy Goat Balrog"})
target = Descriptor.describe(target, observer)
Log.debug(Words.describe_body(target))

# {:agent => <Ninja, :name => "Kenji Scrimshank">, :target => <Goat, :name => "Billy Goat Balrog">, :verb => :attack, :tool => :agent_current_weapon}
puts Words.describe_attack(:attacker => agent, :defender => target, :command => :attack, :tool => :dagger, :result_hash => {:damage_type => :piercing})
puts Words.describe_attack(:defender => agent, :attacker => target, :command => :attack,                   :result_hash => {:damage_type => [:piercing, :blunt, :nonlethal].rand})

target = $core.create(:chest, {:name => "Bosom", :randomize => true})
target_description = Descriptor.describe(target, observer)
Log.debug(Words.describe_container_class(target_description))

target.properties[:open] = true
target_description = Descriptor.describe(target, observer)
Log.debug(Words.describe_container_class(target_description))
Log.debug(Words.describe_composition(target_description))

# Knowledge stuff.
require './knowledge/knowledge'
human_quanta = $core.kb.all_quanta_for_type(:human)
human_quanta.each do |q|
    Log.debug(Words.generate(q.args.dup))
end

# Fred and Jim fell asleep.
# Fred fell asleep, and Jim fell asleep too.
# Fred fell asleep, and so did Jim.
# Fred fell asleep, as did Jim.
