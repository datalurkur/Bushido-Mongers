#!/usr/bin/ruby

require 'raws/db'
require 'game/tables'
require 'game/object_extensions'

require 'test/fake'

Log.setup("main thread", "test")

# Basic DB parsing tests
raw_group = "default"
Log.debug("Loading #{raw_group} raws")
db = ObjectDB.get(raw_group)

# Basic DB loading tests
Log.debug("Testing DB Marshal-ability")
db_data = Marshal.dump(db)
db = nil
db = Marshal.load(db_data)
core = FakeCore.new(db)

# Basic DB listing tests
Log.debug(["Types of items:", db.types_of(:item)])

# Basic item creation tests
test_item_type = :helmet
Log.debug("Creating a #{test_item_type}")
test_item_args = {:quality => :fine, :components => [db.create(core, :iron)]}
test_item = db.create(core, test_item_type, test_item_args)
Log.debug("Test item is a metal? #{test_item.is_a?(:metal)}")
Log.debug("Test item is a constructable? #{test_item.is_a?(:constructed)}")
Log.debug("Test item is a headgear? #{test_item.is_a?(:headgear)}")

# NPC tests
Log.debug(["Types of NPCs:", db.types_of(:npc)])
test_npc_type = :peacekeeper
Log.debug("Creating a #{test_npc_type}")
test_npc = db.create(core, test_npc_type, {:initial_position => FakeRoom.new, :name => "Derpus Maximus"})

Log.debug("Test NPC is a guard? #{test_npc.is_a?(:guard)}")
Log.debug("Test NPC has provocations #{test_npc.provocations.inspect}")

# Body / Corporeal tests
hb = db.create(core, :humanoid_body, {:size => :large})
hb = db.create(core, :arachnoid_body, {:size => :tiny})

# FIXME
# Recipe and command tests
Log.debug("How do I produce a dagger?")
Log.debug(db.info_for(:dagger, :technique))

Log.debug("What can I produce with iron?")
Log.debug(db.info_for(:iron, :used_in))

Log.debug("What can I produce at an anvil?")
anvil_commands = db.info_for(:anvil, :location_of)
Log.debug(["Verbs that happen at an anvil:", anvil_commands])
selected_command = anvil_commands.first
anvil_products = db.find_subtypes(:constructed, {:technique => selected_command})
Log.debug(["Things produced at an anvil by means of #{selected_command}", anvil_products])

Log.debug("What can I do with a hammer?")
Log.debug(db.info_for(:hammer, :used_for))

Log.debug("What sorts of things can I eat?")
Log.debug(db.find_subtypes(:item, {:target_of => :eat}))
