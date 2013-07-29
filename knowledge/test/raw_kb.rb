require './test/fake'
require './knowledge/raw_kb'

Log.setup("Main", "raw_kb_test")

db   = ObjectDB.get("default")
kb   = ObjectKB.new(db, true)

core = CoreWrapper.new

carrot_quanta = kb.all_quanta_for_type(:carrot)

katana_quanta = kb.all_quanta_for_type(:katana)

params = {:position => FakeRoom.new}

smith = core.create_npc(:human, params)
smith.add_knowledge(:constructed, :made, :recipe)

smith.knowledge.get_thing_knowledge(:thing => :constructed, :connector => :made, :property => :recipe)
#smith.add_knowledge_of([:info, :katana], true)
recipes = smith.get_group_knowledge(:katana, :made, :recipe)

Log.debug(["Smith knows about the following katana recipes:", recipes])
