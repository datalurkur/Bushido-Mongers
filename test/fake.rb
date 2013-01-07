class FakeCore
    attr_reader :db
    def initialize(db)
        @db = db
    end
end

class FakeRoom
    def name; "Fake Room"; end
    def add_object(o); end
    def remove_object(o); end
end

unless Object.const_defined?("Message")
    class Message
        class << self
            def register_listener(core, klass, obj); end
            def unregister_listener(core, klass, obj); end
        end
    end
end
