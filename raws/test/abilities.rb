require 'raws/db'
require 'test/fake'

Log.setup("Main", "abilities")

db = ObjectDB.get("default")
core = FakeCore.new(db)

aspect_list = [:strength, :agility, :hammer_fighting, :hide]

aspects = {}

aspect_list.each do |aspect|
    aspects[aspect] = db.create(core, aspect)
end

[
    [:strength,        :easy],
    [:agility,         :simple],
    [:hide,            :normal],
    [:hammer_fighting, :trivial]
].each do |aspect, difficulty|
    Log.debug("Attempting to #{aspect} with difficulty #{difficulty}")
    result = aspects[aspect].attempt(difficulty, aspects)
    Log.debug("Result: #{result}")
end
