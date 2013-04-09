require './test/fake'

Log.setup("Main", "abilities")

core = CoreWrapper.new

params = {:position => FakeRoom.new}

smith = core.populations.create_agent(:human, false, params)
smith.add_knowledge_of([:info, :katana], true)
recipes = smith.get_knowledge_of([:info, :katana, :recipes])
Log.debug(["Smith knows about the following katana recipes:", recipes])

guru = core.populations.create_agent(:human, false, params)
guru.add_knowledge_of([:info], true)
recipes = guru.get_knowledge_of([:info, :katana, :recipes])
Log.debug(["Guru knows about the following katana recipes:", recipes])

apprentice = core.populations.create_agent(:human, false, params)
apprentice.add_knowledge_of([:info, :katana, :recipes])
recipes = apprentice.get_knowledge_of([:info, :katana, :recipes])
Log.debug(["Apprentice knows about the following katana recipes:", recipes])

kenji = core.populations.create_agent(:human, false, params.merge(:name => "Kenji"))

seer = core.populations.create_agent(:human, false, params)
seer.add_knowledge_of([:location], true)
humans = seer.get_knowledge_of([:location, :human])
Log.debug(["Seer knows about the following places humans can be found:", humans])
kenji_loc = seer.get_knowledge_of([:location, "kenji"])
Log.debug(["Seer knows about the following places Kenji can be found:", kenji_loc])
