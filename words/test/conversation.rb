require './util/log'

Log.setup("Main", "test")

tests = [
    # GREETINGS AND SALUTATIONS
    # =========================
    # FIXME

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
    {:phrase => "Do you know where kenji is?",      :result => {:query => true, :query_lookup => :location, :thing => :kenji,   :connector => :is}},
    {:phrase => "Where are rabbits?",               :result => {:query => true, :query_lookup => :location, :thing => :rabbits, :connector => :is}},
    {:phrase => "Where can I find rabbits?",        :result => {:query => true, :query_lookup => :location, :thing => :rabbits, :connector => :find}}
]

require './raws/db'
require './messaging/positional_message'
Message = DebugPositionalMessage
require './messaging/message_defs'
require './test/fake'
require './game/descriptors'
require './game/object_extensions'

core = CoreWrapper.new

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
