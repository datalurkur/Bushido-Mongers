#!/usr/bin/ruby
require 'game/game_core'

game = GameCore.new({})

puts "Are you a bad enough dude to assassinate the shogun?"

while (input = gets)
    result = eval(input)
    puts result
end
