#!/usr/bin/ruby

require 'raws/db'
require 'game/tables'
require 'game/object_extensions'

class FakeCore
    attr_reader :db
    def initialize(db)
        @db = db
    end
end

class FakeRoom
    def name; "Fake Room"; end
    def add_occupant(o); end
end

Log.setup("main thread", "test")

raw_group = "default"

Log.debug("Loading #{raw_group} raws")
db = ObjectDB.new(raw_group)

Log.debug("Testing DB Marshal-ability")
db_data = Marshal.dump(db)
db = nil
db = Marshal.load(db_data)
core = FakeCore.new(db)

Log.debug(["Types of items:", db.types_of(:item)])

test_item_type = :cap
Log.debug("Creating a #{test_item_type}")
test_item_args = {:quality => :fine, :materials => [db.create(core, :iron)]}
test_item = db.create(core, test_item_type, test_item_args)

Log.debug("Test item is a metal? #{test_item.is_a?(:metal)}")
Log.debug("Test item is a constructable? #{test_item.is_a?(:constructable)}")
Log.debug("Test item is a headgear? #{test_item.is_a?(:headgear)}")

Log.debug(["Types of NPCs:", db.types_of(:npc)])

test_npc_type = :peacekeeper
Log.debug("Creating a #{test_npc_type}")
test_npc = db.create(core, test_npc_type, {:initial_position => FakeRoom.new, :name => "Derpus Maximus"})

Log.debug("Test NPC is a guard? #{test_npc.is_a?(:guard)}")
Log.debug("Test NPC has provocations #{test_npc.provocations.inspect}")

hb = db.create(core, :humanoid_body, {:size => :large})
hb = db.create(core, :arachnoid_body, {:size => :tiny})
