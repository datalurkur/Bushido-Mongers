require './test/fake'
require './knowledge/raw_kb'

Log.setup("Main", "raw_kb_test")

db   = ObjectDB.get("default")
kb   = ObjectKB.new(db, true)

core = CoreWrapper.new

carrot_quanta = kb.all_quanta_for_type(:carrot)
katana_quanta = kb.all_quanta_for_type(:katana)

human_quanta = kb.all_quanta_for_type(:human)
Log.debug(human_quanta)

params = {:position => FakeRoom.new}

smith = core.create_npc(:human, params)
smith.add_knowledge(:melee_weapon, :made, :recipe)
recipes = smith.get_knowledge_of_group(:katana, :made, :recipe)
Log.debug(["Smith knows about the following katana recipes:", recipes.inspect])

guru = core.create_npc(:human, params)
guru.add_knowledge(:constructed, :made, :recipe)
recipes = guru.get_knowledge_of_group(:katana, :made, :recipe)
Log.debug(["Guru knows about the following katana recipes:", recipes.inspect])

apprentice = core.create_npc(:human, params)
apprentice.add_knowledge(:katana, :made, :recipe)
recipes = apprentice.get_knowledge_of_group(:melee_weapon, :made, :recipe)
Log.debug(["Apprentice knows about the following weapon recipes:", recipes.inspect])
