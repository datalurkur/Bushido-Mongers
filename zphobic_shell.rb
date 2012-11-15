#!/usr/bin/ruby
require 'game/game_core'

game = GameCore.new({})

while (input = gets)
    result = eval(input)
    puts result
end
