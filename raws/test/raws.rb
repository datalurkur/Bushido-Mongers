require './raws/db'
require './game/tables'
require './game/object_extensions'
require './test/fake'
Log.setup("Main", "test")

# Basic DB parsing tests
raw_group = "default"

# Basic DB loading tests
db = ObjectDB.get(raw_group)
Log.debug("Testing DB Marshal-ability")
db_data = Marshal.dump(db)
db = nil
db = Marshal.load(db_data)
db = nil

$core = CoreWrapper.new

# Basic DB listing tests
Log.debug(["Number of types of objects:", $core.db.types_of(:object).size])

# Basic item creation tests
test_item_type = :head_armor
Log.debug("Creating a #{test_item_type}")
test_item_args = {:creator => $core.create(:iron), :relative_size => :medium, :quality => :fine, :components => [$core.create(:iron)], :position => FakeRoom.new}
test_item = $core.create(test_item_type, test_item_args)
Log.debug("Test item is a metal? #{test_item.is_type?(:metal)}")
Log.debug("Test item is a constructable? #{test_item.is_type?(:constructed)}")
Log.debug("Test item is a head armor? #{test_item.is_type?(:hear_armor)}")

# NPC tests
Log.debug(["Types of NPCs:", $core.db.types_of(:archetype)])

def test_npc(db, test_npc_type, name)
#    Log.debug(["Creating a #{test_npc_type} with raw info", db.raw_info_for(test_npc_type)])
    $core.create(test_npc_type, :position => FakeRoom.new, :name => name)
end

def test_test_npc(db, test_npc_type, name)
    test_npc = test_npc(db, test_npc_type, name)
    Log.debug(test_npc)
    Log.debug("Test NPC is a guard? #{test_npc.is_type?(:guard)}")
    if test_npc.properties[:provocations]
        Log.debug(["Test NPC has provocations", test_npc.properties[:provocations]])
    end
end

#test_test_npc($core.db, :peacekeeper, "Derpus Maximus")
#test_test_npc(db, :giant_spider, "Leggus Maximus")

# Recipe and command tests
Log.debug("How do I produce a dagger?")
Log.debug($core.db.info_for(:dagger, :recipes))

Log.debug("What can I produce with iron?")
Log.debug($core.db.info_for(:iron, :used_in))

Log.debug("What can I produce at an anvil?")
anvil_commands = $core.db.info_for(:anvil, :location_of)
Log.debug(["Verbs that happen at an anvil:", anvil_commands])
selected_command = anvil_commands.first
anvil_products = $core.db.find_subtypes(:constructed, {:recipes => {:technique => selected_command}})
Log.debug(["Things produced at an anvil by means of #{selected_command}", anvil_products])

Log.debug("What can I do with a hammer?")
Log.debug($core.db.info_for(:hammer, :used_for))

Log.debug("What sorts of things can I eat?")
Log.debug($core.db.find_subtypes(:object, {:target_of => :eat}))

# Zone tests
begin
    require 'world/zone'

    Log.debug(["types_of(:zone):", $core.db.types_of(:zone)])
    Log.debug("Meadow has keywords: #{$core.db.info_for(:meadow, :keywords)}")

    zone_params = Zone.get_params($core, nil, 3)
    Log.debug(zone_params)
    zone2 = Zone.get_params($core, zone_params[:type], 2)
    Log.debug(zone2)
end

# item composition tests
begin
    bp = $core.create(:backpack, {:randomize => true})
    Log.debug(bp)
    carrot = $core.create(:carrot, :size=>:medium)
    Log.debug(carrot)
    bp.add_object(carrot)
    Log.debug(bp)
    Log.debug(bp.container_contents(:internal))
    Log.debug(bp.container_contents(:external))
end

# test test.raw
begin
    bp = $core.create(:backpack, {:randomize => true})
    Log.debug(bp)
    carrot = $core.create(:carrot, :size=>:medium)
    Log.debug(carrot)
    bp.add_object(carrot)
    Log.debug(bp)

    sbp = $core.create(:backpack, {:randomize => true})
    Log.debug(sbp)
    sbp.add_object(carrot)
    carrot = $core.create(:carrot, :size=>:medium)
    sbp.add_object(carrot, :external)
    Log.debug(sbp)
end
