require './game/cores/default'
require './knowledge/raw_kb'

class FakeCore < DefaultCore
    # No need to call setup separately for FakeCore.
    def initialize
        super
        setup({})
    end

    def setup(args)
        # Cribbed directly from GameCore.setup. Does everything except set
        # up the world and the world managers.
        Log.info("Setting up fake core")

        # Setup various game variables
        # ----------------------------
        @tick_rate = args[:tick_rate] || (30)
        @ticking   = false

        # Read the raws
        # -------------
        raw_group = args[:raw_group] || "default"
        @db       = ObjectDB.get(raw_group)
        @kb       = ObjectKB.new(@db, true)
        @words_db = WordParser.load
        WordParser.read_raws(@words_db, @db)

        # Prepare for object creation
        # ---------------------------
        @uid_count            = 0
        @awaiting_destruction = []

        @setup = true
    end
end

class FakeRoom
    def initialize(core=nil, name="FakeRoom", params={})
        @core = core
    end
    def name; "Fake Room"; end
    def get_contents(t);
        raise(ArgumentError, "Invalid room content type #{t}.") unless t == :internal
        @objects.collect { |o_id| @core.lookup(o_id) }
    end
    def add_object(o,t=nil)
        @objects ||= []
        @objects << o.uid
    end
    def remove_object(o,t=nil)
        @objects ||= []
        @objects.delete(o.uid)
    end
    def component_destroyed(o,t,d); remove_object(o,t); end
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
