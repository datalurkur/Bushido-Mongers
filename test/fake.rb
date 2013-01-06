class FakeCore
    attr_reader :db
    def initialize(db)
        @db = db
    end
end

class FakeRoom
    def name; "Fake Room"; end
    def add_occupant(o); end
    def remove_occupant(o); end
    def contents; @contents ||= []; end
end

