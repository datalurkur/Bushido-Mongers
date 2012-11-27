#!/usr/bin/ruby
require 'game/game_core'

game = GameCore.new({})

puts "Are you a bad enough dude to assassinate the shogun?"

random_zone = game.world.get_zone(rand(game.world.size), rand(game.world.size))

while (input = gets)
    result = eval(input)
    puts result
end
