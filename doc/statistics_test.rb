class Float
    def pretty
        "%.3f" % self
    end
end

def get_std_dev(set, mean)
    mod_results = set.collect { |i| (i - mean) ** 2 }
    (mod_results.inject(&:+) / mod_results.size) ** 0.5
end

def stats_of(runs, &block)
    results = []
    puts "Performing #{runs} iterations"
    runs.times { results << block.call }

    min     = results.min
    max     = results.max
    mean    = results.inject(&:+) / results.size
    std_dev = get_std_dev(results, mean)

    puts "Mean:     #{mean.pretty}"
    puts "Std.Dev.: #{std_dev.pretty}"
    puts "Min:      #{min.pretty}"
    puts "Max:      #{max.pretty}"
end

def skill_roll(a,s,f)
    s + (a * ((rand()*(1.0-f)) + (f-0.5)))
end

def do_test_with(a,s,f)
    puts "-" * 100
    puts "Coefficient / Skill / Familiarity : #{[a,s,f].inspect}"
    stats_of(100000) {
        skill_roll(a,s,f)
    }
end

stats_of(10000) { rand()*(0.5) }

puts "=" * 100
puts "Low skill / nominal familiarity"
do_test_with(0.1, 0.25, 0.5)
do_test_with(0.2, 0.25, 0.5)
do_test_with(0.5, 0.25, 0.5)

puts "=" * 100
puts "Nominal skill / nominal familiarity"
do_test_with(0.1, 0.5, 0.5)
do_test_with(0.2, 0.5, 0.5)
do_test_with(0.5, 0.5, 0.5)

puts "=" * 100
puts "Nominal skill / low familiarity"
do_test_with(0.1, 0.5, 0.25)
do_test_with(0.2, 0.5, 0.25)
do_test_with(0.5, 0.5, 0.25)

puts "=" * 100
puts "Nominal skill / high familiarity"
do_test_with(0.1, 0.5, 0.75)
do_test_with(0.2, 0.5, 0.75)
do_test_with(0.5, 0.5, 0.75)

puts "=" * 100
puts "High skill / high familiarity"
do_test_with(0.1, 0.75, 0.75)
do_test_with(0.2, 0.75, 0.75)
do_test_with(0.5, 0.75, 0.75)
