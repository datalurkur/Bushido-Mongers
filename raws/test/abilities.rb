require 'raws/db'
require 'test/fake'

Log.setup("Main", "abilities")

db = ObjectDB.get("default")
core = CoreWrapper.new

aspect_list = [:strength, :agility, :intrinsic_fighting_skill, :hide_skill]

aspects = {}

aspect_list.each do |aspect|
    aspects[aspect] = core.create(aspect)
end

[
    [:strength,                 :easy],
    [:agility,                  :simple],
    [:hide_skill,               :normal],
    [:intrinsic_fighting_skill, :trivial]
].each do |aspect, difficulty|
    Log.debug("Attempting to #{aspect} with difficulty #{difficulty}")
    result = aspects[aspect].attempt(difficulty, aspects)
    Log.debug("Result: #{result}")
end
