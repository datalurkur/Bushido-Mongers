require './util/log'
require './util/basic'

Log.setup("Vocabulary Test", "wordtest")

require './words/words'
require './test/fake'

$core = FakeCore.new

Log.debug($core.words_db.gen_area_name({:type => :mountain, :keywords => [:beautiful]}))
Log.debug($core.words_db.gen_area_name({:type => :sewer,    :keywords => [:dank]}))

s = Words::State.new
raise unless s.eql?(s)
sp = s.dup
sp.voice = :passive
raise if s.eql?(sp)
raise if sp.eql?(s)
s  = Words::State.new(:past, :present)
s2 = Words::State.new(:past, :present)
raise unless s.eql?(s2)
raise unless s2.eql?(s)

Log.debug(
    $core.words_db.describe_room(
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
    Log.debug($core.words_db.gen_sentence(:agent => :John, :command => :move, :destination => :west, :state=>state))
    Log.debug($core.words_db.gen_sentence(:agent => :John, :action  => :see,  :target      => :Mary, :state=>state))
end

def john_and_mary_tenses(state)
    Words::State::FIELDS[:tense].each do |t|
        state.tense = t
        john_and_mary(state)
    end
end

s = Words::State.new
john_and_mary_tenses(s)
s.aspect = :progressive
john_and_mary_tenses(s)

Log.debug($core.words_db.gen_copula)
Log.debug($core.words_db.gen_copula(:complement => :sunny))

Log.debug(
    $core.words_db.gen_sentence(
        :subject => [:Billy_Bob, :beaver],
        :verb    => :walk,
        :destination => :bar
    )
)

Log.debug(
    $core.words_db.gen_sentence(
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

# Body descriptions.
observer = $core.create_npc(:human, :name => "Kenji Skrimshank", :position => $core.create(FakeRoom))
Log.debug($core.words_db.describe_body(observer))
Log.debug($core.words_db.describe_inventory(observer))
# Test missing parts.
kenji_leg = observer.get_contents(:external).find { |bp| bp.get_type == :leg }
observer.component_destroyed(kenji_leg, :external, observer)
Log.debug($core.words_db.describe_body(observer))
kenji_leg = observer.get_contents(:external).find { |bp| bp.get_type == :leg }
observer.component_destroyed(kenji_leg, :external, observer)
Log.debug($core.words_db.describe_body(observer))

#args = {:agent => agent}
#Log.debug($core.words_db.describe_inventory(args))

kenji_arm = observer.get_contents(:external).find { |bp| bp.get_type == :arm }
Log.debug($core.words_db.describe_composition(kenji_arm))

target = $core.create(:goat, {:position => $core.create(FakeRoom), :name => "Billy Goat Balrog"})
#target = Descriptor.describe(target, observer)
Log.debug($core.words_db.describe_body(target))

# {:agent => <Ninja, :name => "Kenji Scrimshank">, :target => <Goat, :name => "Billy Goat Balrog">, :verb => :attack, :tool => :agent_current_weapon}
puts $core.words_db.describe_attack(:attacker => observer, :defender => target, :command => :attack, :tool => :dagger, :result_hash => {:damage_type => :piercing})
puts $core.words_db.describe_attack(:defender => observer, :attacker => target, :command => :attack,                   :result_hash => {:damage_type => [:piercing, :blunt, :nonlethal].rand})

target = $core.create(:chest, {:name => "Bosom", :randomize => true})
#target_description = Descriptor.describe(target, observer)
Log.debug($core.words_db.describe_composition(target))

target.properties[:open] = true
#target_description = Descriptor.describe(target, observer)
#Log.debug($core.words_db.describe_container_class(target_description))
Log.debug($core.words_db.describe_composition(target))

Log.debug($core.words_db.identity_copula(observer).sentence)
Log.debug($core.words_db.type_copula(observer).sentence)

# Knowledge stuff.
require './knowledge/knowledge'
human_quanta = $core.kb.all_quanta_for_type(:human)
#Log.debug(human_quanta)
human_quanta.each do |q|
    Log.debug($core.words_db.generate(q.args.dup))
end

# Fred and Jim fell asleep.
# Fred fell asleep, and Jim fell asleep too.
# Fred fell asleep, and so did Jim.
# Fred fell asleep, as did Jim.
