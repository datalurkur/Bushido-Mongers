require './game/cores/default'
require './knowledge/raw_kb'
require './game/core_loader'

class FakeLobby
    include GameCoreLoader

    def send_to_user(username, message)
        # --
    end
end

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
        @words_db = Lexicon.new(@db)

        # Prepare for object creation
        # ---------------------------
        @uid_count            = 0
        @awaiting_destruction = []

        @setup = true
    end
end

require './world/room'
class FakeRoom < Room
    def initialize(core, uid, params)
        params[:name] ||= "FakeRoom"
        super(core, uid, params)
    end
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
