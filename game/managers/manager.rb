class Manager
    def initialize(core)
        @core = core
    end

    def listens_for; []; end

    def register_as_listener
        listens_for.each do |message_type|
            Message.register_listener(@core, message_type, self)
        end
    end

    def unregister_as_listener
        listens_for.each do |message_type|
            Message.unregister_listener(@core, message_type, self)
        end
    end

    def setup
        register_as_listener
    end

    def teardown
        unregister_as_listener
    end

    def unpack_custom(hash)
        register_as_listener
    end
end
