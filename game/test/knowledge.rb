require './test/fake'

Log.setup("Main", "abilities")

core = CoreWrapper.new

smith = core.create_agent(:human, false, {})
smith.add_knowledge_of([:info, :katana], true)
recipes = smith.get_knowledge_of([:info, :katana, :recipes])
Log.debug(["Smith knows about the following katana recipes:", recipes])

guru = core.create_agent(:human, false, {})
guru.add_knowledge_of([:info], true)
recipes = guru.get_knowledge_of([:info, :katana, :recipes])
Log.debug(["Guru knows about the following katana recipes:", recipes])
