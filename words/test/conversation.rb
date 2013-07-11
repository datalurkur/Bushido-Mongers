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
    {:phrase => "Where is kenji?",                  :result => {:query => true, :lookup => :location, :noun => :kenji}},
    {:phrase => "Where is Kenji",                   :result => {:query => true, :lookup => :location, :noun => :kenji}},
    {:phrase => "Do you know where kenji is?",      :result => {:query => true, :lookup => :location, :noun => :kenji}},
    {:phrase => "Where are rabbits?",               :result => {:query => true, :lookup => :location, :noun => :rabbit}},
    {:phrase => "Where can I find rabbits?",        :result => {:query => true, :lookup => :location, :noun => :rabbit}},
    {:phrase => "How do I make a katana?",          :result => [:info, :katana, :recipe]},
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


tests.each do |test|
    message = speaker.say(receiver, test[:phrase])
    test_result = Conversation.at_message(receiver, message)

    if test_result != test[:result]
        Log.error(["Phrase was incorrectly parsed", test, test_result])
        raise
    end
end
