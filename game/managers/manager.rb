class Manager
    def initialize(core)
        @core = core
    end

    def listens_for; []; end

    def setup
        listens_for.each do |message_type|
            Message.register_listener(@core, message_type, self)
        end
    end

    def teardown
        listens_for.each do |message_type|
            Message.unregister_listener(@core, message_type, self)
        end
    end
end
