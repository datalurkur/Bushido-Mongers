require './messaging/message'
require './game/core_loader'
require './game/cores/default'

Log.setup("Main", "core_loader_test")

class TestCoreLoader
    include GameCoreLoader

    def initialize
        @core = DefaultCore.new
        @core.setup

        @extra_info = {
            :name    => "TestCoreLoader",
            :creator => "TestCreator",
            :some_random_value => 10
        }
    end

    def test
        uid                = save_core(@core, @extra_info)
        saved_cores        = get_saved_cores_info
        @core, @extra_info = load_core(uid)
    end
end

t = TestCoreLoader.new
3.times { t.test }
