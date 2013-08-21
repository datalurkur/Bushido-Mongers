require './util/log'
require './util/basic'

Log.setup("Vocabulary Test", "wordtest")

require './words/words'
require './test/fake'

# We want the raws in the words db, which setting up a core accomplishes.
$core = FakeCore.new

10.times do |i|
    Log.debug(Words::Adjective.rand)
end

10.times do |i|
    Log.debug(Words::Noun.rand)
end

10.times do |i|
    Log.debug(Words.random_name)
end

