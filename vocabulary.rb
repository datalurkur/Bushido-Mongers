class Noun
    class << self
        def random
            (@loaded = File.readlines('nouns.txt')) unless @loaded
            @loaded[rand(@loaded.size)]
        end
    end
end
