require './raws/db'
require './test/fake'

Log.setup("Main", "abilities")

db = ObjectDB.get("default")
core = FakeCore.new

aspect_list = [:strength, :agility, :intrinsic_fighting, :stealth]

aspects = {}

aspect_list.each do |aspect|
    aspects[aspect] = core.create(aspect)
end

[
    [:strength,                 :easy],
    [:agility,                  :simple],
    [:stealth,                  :normal],
    [:intrinsic_fighting,       :trivial]
].each do |aspect, difficulty|
    Log.debug("Attempting to #{aspect} with difficulty #{difficulty}")
    result = aspects[aspect].make_check(aspects)
    Log.debug("Result: #{result.inspect}")
end
