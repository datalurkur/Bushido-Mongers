require './util/coverage'

CodeCoverage.setup

class A
    def called_method(a, b, c)
        [a, b, c]
    end

    def uncalled_method(d, e, f)
        [d, e, f]
    end
end

a = A.new
result = a.called_method(1,2,3)
unless result === [1,2,3]
    puts "Test failed - method destroyed"
end
result = a.called_method(2,3,4)

puts CodeCoverage.results.inspect
