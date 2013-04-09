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
    {:phrase => "Where is kenji?",                  :result => [:location, "kenji"]},
    {:phrase => "Where can I find rabbits?",        :result => [:location, :rabbit]},
    {:phrase => "How do I make a katana?",          :result => [:info, :katana, :recipe]},
]

tests.each do |test|
    # FIXME ZPHOBIC - Fill in the appropriate method call once the grammar stuff is ready
    test_result = test[:phrase]
    if test_result != test[:result]
        Log.error(["Phrase was incorrectly parsed", test, test_result])
        raise
    end
end
