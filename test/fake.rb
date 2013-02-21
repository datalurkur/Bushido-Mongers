class FakeCore
    attr_reader :db
    def initialize(db)
        @db = db
    end
    def create(type, hash)
        @db.create(self, type, hash)
    end
end

class FakeRoom
    def name; "Fake Room"; end
    def add_object(o,t=nil); end
    def remove_object(o); end
    def monicker() self.name; end
end

unless Object.const_defined?("Message")
    class Message
        class << self
            def register_listener(core, klass, obj); end
            def unregister_listener(core, klass, obj); end
            def dispatch(core, type, args={}); end
        end
    end
end
