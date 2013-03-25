class FakeCore
    attr_reader :db
    def initialize(db)
        Message.setup(self)

        @db = db
    end
    def create(type, hash={})
        @db.create(self, type, 0, hash)
    end
    def flag_for_destruction(object, destroyer)
    end
end

class FakeRoom
    def name; "Fake Room"; end
    def add_object(o,t=nil,rm=nil); end
    def remove_object(o); end
    def zone_info(); {}; end
    def monicker() self.name; end
end

unless Object.const_defined?("Message")
    class Message
        class << self
            def setup(core); end
            def register_listener(core, klass, obj); end
            def unregister_listener(core, klass, obj); end
            def dispatch(core, type, args={}); end
            def dispatch_positional(core, locations, type, args={}); end
            def change_listener_position(core, listener, position, old_position); end
            def clear_listener_position(core, listener, position); end
        end
    end
end
