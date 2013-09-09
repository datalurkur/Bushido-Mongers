require './util/log'

Log.setup("Main", "test")

tests = [
    # GREETINGS AND SALUTATIONS
    # =========================
    # <basic response to PC / human arrival>
    # <talk about weather, current events, or nothing, depending on inclination>
    # <response, discussion of quest / help needed>

    # TRADING AND TRANSACTIONS
    # ========================
    # FIXME

    # QUESTS
    # ======
    # FIXME

    # KNOWLEDGE-BASED QUESTION TESTS
    # ==============================
    # Names don't have to be in any particular format
    # FIXME - These will probably look different and use a different API before being passed to the knowledge system as a query
    {:phrase => "What is a human?",                 :result => {:query => true, :query_lookup => :object, :thing => :human,     :connector => :is}},
    {:phrase => "How to make a katana?",            :result => {:query => true, :query_lookup => :task,   :thing => :katana,    :connector => :make}},
    {:phrase => "How do I make a katana?",          :result => {:query => true, :query_lookup => :task,   :thing => :katana,    :connector => :make}},
    {:phrase => "Where is kenji?",                  :result => {:query => true, :query_lookup => :location, :thing => :kenji,   :connector => :is}},
    {:phrase => "Where is Kenji",                   :result => {:query => true, :query_lookup => :location, :thing => :kenji,   :connector => :is}},
    {:phrase => "Where can I find Kenji",           :result => {:query => true, :query_lookup => :location, :thing => :kenji,   :connector => :find}},
    {:phrase => "Do you know where kenji is?",      :result => {:query => true, :query_lookup => :location, :thing => :kenji,   :connector => :is}},
    {:phrase => "Where are rabbits?",               :result => {:query => true, :query_lookup => :location, :thing => :rabbits, :connector => :is}},
    {:phrase => "Where can I find rabbits?",        :result => {:query => true, :query_lookup => :location, :thing => :rabbits, :connector => :find}},
    {:phrase => "What is your name?",               :result => {:query => true, :query_lookup => :object,   :thing => :self,    :connector => :have, :property=>:name, :thing_adjs => [ :your ]}}
    # "How much does a tunic cost?"

    # AREA KNOWLEDGE

    # "Does ivy grow near here?" / "Where do blisterworts grow?"
    # "What can I make with rat's hair?"
    # "Where can I buy a hammer?"
    # "Are thieves common in these parts?"
    # How far is it to the Deserted Castle?
    # What is the name of this area?

    # SELF KNOWLEDGE

    # What is your name?
    # What is your clan's name?
    # What is your shugo's name?
    # What is your job?
    # Do you have any relatives?
    # Do you know Archimedes?
    # Did you kill the rat?

    # REQUESTS
    # <@datalurkur> A user could propose quests to NPCs

    # "If I killed Hun-shi, how much would you pay me?" / "How much would you pay me to kill Hun-shi?" # ADVANCED!
    # How much will you give me for these iron daggers?
    # "Do you have any high-quality swords?"
    # Will you train me to use armor?

    # PREFERENCES / OPINIONS
    # <@datalurkur> I would imagine we can cue off of keywords like "favourite" and "prefer" and "like" to jump into personality code

    # What do you think of the emperor?
    # What do you think of my sword technique?
    # What is your favorite food?
    # What is your favourite colour?
    # "What is the emperor's favorite food?" / "Do you know what the emperor likes to eat?""
    # "What types of weapons do you prefer?""

]

require './raws/db'
require './messaging/positional_message'
Message = DebugPositionalMessage
require './messaging/message_defs'
require './test/fake'
require './game/descriptors'
require './game/object_extensions'

core = FakeCore.new

speaker  = core.create_npc(:human, :name => "Kenji Skrimshank", :position => FakeRoom.new)
receiver = core.create_npc(:human, :name => "Bob",              :position => FakeRoom.new)

receiver.add_knowledge(:katana, :make, :recipe)

# Tests proper decomposition, but not the response.
tests.each do |test|
    message = speaker.say(receiver, test[:phrase], true)
    test_result = Conversation.at_message(receiver, message)

    if test_result != test[:result]
        Log.error(["Phrase was incorrectly parsed", test_result, test[:result]])
        raise
    end
end
