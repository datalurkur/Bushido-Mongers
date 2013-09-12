require './test/fake'
require './knowledge/raw_kb'

Log.setup("Main", "raw_kb_test")

db     = ObjectDB.get("default")
okb    = ObjectKB.new(db, true)

packed = ObjectKB.pack(okb)
Log.debug(packed)
kb     = ObjectKB.unpack(db, packed)

core = FakeCore.new

carrot_quanta = kb.all_quanta_for_type(:carrot)
katana_quanta = kb.all_quanta_for_type(:katana)

human_quanta = kb.all_quanta_for_type(:human)
Log.debug(human_quanta)

params = {:position => core.create(FakeRoom)}

smith = core.create_npc(:human, params)
smith.add_knowledge(:melee_weapon, :make, :recipe)
recipes = smith.get_knowledge(:katana, :make, :recipe)
Log.debug(["Smith knows about the following katana recipes:", recipes.inspect])

guru = core.create_npc(:human, params)
guru.add_knowledge(:constructed, :make, :recipe)
recipes = guru.get_knowledge(:katana, :make, :recipe)
Log.debug(["Guru knows about the following katana recipes:", recipes.inspect])

apprentice = core.create_npc(:human, params)
apprentice.add_knowledge(:katana, :make, :recipe)
recipes = apprentice.get_knowledge(:melee_weapon, :make, :recipe)
Log.debug(["Apprentice knows about the following weapon recipes:", recipes.inspect])

=begin
seer = core.create_npc(:human, params)
seer.add_knowledge_of([:location], true)
humans = seer.get_knowledge_of([:location, :human])
Log.debug(["Seer knows about the following places humans can be found:", humans])
kenji_loc = seer.get_knowledge_of([:location, "kenji"])
Log.debug(["Seer knows about the following places Kenji can be found:", kenji_loc])
=end
