require 'world/zone'

module ZoneWithKeywords
    def keywords
        @keywords ||= []
    end

    def add_keywords(keywords)
        keywords.each { |kw| add_keyword(kw) }
    end

    def add_keyword(keyword)
        keywords << keyword
        keywords.uniq!
    end

    def remove_keyword(keyword)
        keywords.delete(keyword)
    end
end

class Room < ZoneLeaf
    include ZoneWithKeywords

    attr_reader :contents

    def initialize(name, keywords=[])
        add_keywords(keywords)
        super(name)

        @contents = []
    end
end

class Area < ZoneContainer
    include ZoneWithKeywords
    
    def initialize(name, size, depth, keywords=[])
        add_keywords(keywords)
        super(name, size, depth)
    end
end
