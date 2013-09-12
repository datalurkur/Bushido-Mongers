require './messaging/message'
require './game/cores/default'

Log.setup("Main", "core_test")

core = DefaultCore.new
core.setup(:world_depth => 2, :world_size => 2)

packed = DefaultCore.pack(core)
Log.debug("Packed data : #{packed.class.inspect}")
core = DefaultCore.unpack(packed)
