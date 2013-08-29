require './util/repro'
require './messaging/positional_message'

Log.setup("main", "repro_inspection")

unless ARGV[0]
  puts "Please specify a repro file to load"
  exit
end

repro = Repro.load(ARGV[0])

puts "Repro loaded from #{ARGV[0]}"
puts "============================"
puts "Seed: #{repro.seed}"
puts "Events:"
repro.events.each do |event|
  puts "\t\t#{"%04s" % event.offset} : #{"%08s" % (event.type || "none").inspect} : #{event.data.inspect}"
end
