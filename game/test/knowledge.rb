require './test/fake'

Log.setup("Main", "abilities")

core = CoreWrapper.new

params = {:position => FakeRoom.new}

smith = core.create_npc(:human, params)
smith.add_knowledge_of([:info, :katana], true)
recipes = smith.get_knowledge_of([:info, :katana, :recipes])
Log.debug(["Smith knows about the following katana recipes:", recipes])

guru = core.create_npc(:human, params)
guru.add_knowledge_of([:info], true)
recipes = guru.get_knowledge_of([:info, :katana, :recipes])
Log.debug(["Guru knows about the following katana recipes:", recipes])

apprentice = core.create_npc(:human, params)
apprentice.add_knowledge_of([:info, :katana, :recipes])
recipes = apprentice.get_knowledge_of([:info, :katana, :recipes])
Log.debug(["Apprentice knows about the following katana recipes:", recipes])

kenji = core.create_npc(:human, params.merge(:name => "Kenji"))

seer = core.create_npc(:human, params)
seer.add_knowledge_of([:location], true)
humans = seer.get_knowledge_of([:location, :human])
Log.debug(["Seer knows about the following places humans can be found:", humans])
kenji_loc = seer.get_knowledge_of([:location, "kenji"])
Log.debug(["Seer knows about the following places Kenji can be found:", kenji_loc])
