require './messaging/message'
require './game/cores/default'
require './util/debug'

Log.setup("Main", "core_test")

core = DefaultCore.new
core.setup(:world_depth => 2, :world_size => 2)

packed = DefaultCore.pack(core)
types = Debug.deep_search_types(packed, [ObjectDB,ObjectKB,WordDB,BushidoObject])
Log.debug("Packed data includes: #{types.inspect}")
core = DefaultCore.unpack(packed)
repacked = DefaultCore.pack(core)
diffs = Debug.deep_compare(packed, repacked)
failed = false
diffs.each do |diff|
    next if diff[0][0] == :saved_on
    Log.error("Diff found at #{diff[0].inspect} - #{diff[1].inspect} | #{diff[2].inspect}")
    failed = true
end
exit(failed ? 1 : 0)
