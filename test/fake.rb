require './game/core'

class CoreWrapper < GameCore
    def initialize
        super
        Log.info("Setting up fake core")

        @uid_count = 0
        @awaiting_destruction = []

        # Read the raws
        @db       = ObjectDB.get("default")
        # And the word text information.
        @words_db = WordParser.load
        # And finally read in some basic noun & adjective information from the raws db.
        WordParser.read_raws(@words_db, @db)

        @population_manager = PopulationManager.new(self)
        @population_manager.setup
    end
end

class FakeRoom
    def name; "Fake Room"; end
    def contents; @objects; end
    def add_object(o,t=nil)
        @objects ||= []
        @objects << o
    end
    def remove_object(o,t=nil)
        @objects ||= []
        @objects.delete(o)
    end
    def component_destroyed(o,t,d); end
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
