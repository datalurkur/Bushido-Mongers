require './raws/db'
require './game/tables'
require './game/object_extensions'
require './test/fake'
Log.setup("Main", "test")

# Basic DB parsing tests
raw_group = "default"
Log.debug("Loading #{raw_group} raws")
db = ObjectDB.get(raw_group)

# Basic DB loading tests
Log.debug("Testing DB Marshal-ability")
db_data = Marshal.dump(db)
db = nil
db = Marshal.load(db_data)
$core = FakeCore.new(db)

# Basic DB listing tests
Log.debug(["Number of types of items:", db.types_of(:item).size])

# Basic item creation tests
test_item_type = :head_armor
Log.debug("Creating a #{test_item_type}")
test_item_args = {:relative_size => :medium, :quality => :fine, :components => [db.create($core, :iron)], :position => FakeRoom.new}
test_item = db.create($core, test_item_type, test_item_args)
Log.debug("Test item is a metal? #{test_item.is_type?(:metal)}")
Log.debug("Test item is a constructable? #{test_item.is_type?(:constructed)}")
Log.debug("Test item is a head armor? #{test_item.is_type?(:hear_armor)}")

# NPC tests
Log.debug(["Types of NPCs:", db.types_of(:npc)])

def test_npc(db, test_npc_type, name)
#    Log.debug(["Creating a #{test_npc_type} with raw info", db.raw_info_for(test_npc_type)])
    db.create($core, test_npc_type, :position => FakeRoom.new, :name => name)
end

def test_test_npc(db, test_npc_type, name)
    test_npc = test_npc(db, test_npc_type, name)
    Log.debug(test_npc)
    Log.debug("Test NPC is a guard? #{test_npc.is_type?(:guard)}")
    if test_npc.has_property?(:provocations)
        Log.debug(["Test NPC has provocations", test_npc.provocations])
    end
end

test_test_npc(db, :peacekeeper, "Derpus Maximus")
#test_test_npc(db, :giant_spider, "Leggus Maximus")

# Body / Corporeal tests
hb = db.create($core, :humanoid_body, :relative_size => :large)
hb = db.create($core, :arachnoid_body, :relative_size => :tiny)

# Recipe and command tests
Log.debug("How do I produce a dagger?")
Log.debug(db.info_for(:dagger, :recipes))

Log.debug("What can I produce with iron?")
Log.debug(db.info_for(:iron, :used_in))

Log.debug("What can I produce at an anvil?")
anvil_commands = db.info_for(:anvil, :location_of)
Log.debug(["Verbs that happen at an anvil:", anvil_commands])
selected_command = anvil_commands.first
anvil_products = db.find_subtypes(:constructed, {:recipes => {:technique => selected_command}})
Log.debug(["Things produced at an anvil by means of #{selected_command}", anvil_products])

Log.debug("What can I do with a hammer?")
Log.debug(db.info_for(:hammer, :used_for))

Log.debug("What sorts of things can I eat?")
Log.debug(db.find_subtypes(:item, {:target_of => :eat}))

# Zone tests
begin
    require 'world/zone'

    Log.debug(["types_of(:zone):", db.types_of(:zone)])
    Log.debug("Meadow has keywords: #{db.info_for(:meadow, :keywords)}")

    zone_params = Zone.create($core, nil, 3)
    Log.debug(zone_params)
    zone2 = Zone.create($core, zone_params[:zone], 2)
    Log.debug(zone2)
end

# item composition tests
begin
    bp = db.create($core, :leather_backpack)
    Log.debug(bp)
    carrot = db.create($core, :carrot, :size=>:medium)
    Log.debug(carrot)
    bp.insert_object(carrot)
    Log.debug(bp)
    Log.debug(bp.internal_objects)
    Log.debug(bp.external_objects)
end

# test test.raw
begin
    bp = db.create($core, :leather_backpack)
    Log.debug(bp)
    carrot = db.create($core, :carrot, :size=>:medium)
    Log.debug(carrot)
    bp.insert_object(carrot)
    Log.debug(bp)

    sbp = db.create($core, :leather_backpack)
    Log.debug(sbp)
    sbp.insert_object(carrot)
    carrot = db.create($core, :carrot, :size=>:medium)
    sbp.attach_object(carrot)
    Log.debug(sbp)
end
