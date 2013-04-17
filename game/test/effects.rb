require './messaging/positional_message'
Message = PositionalMessage
require './messaging/message_defs'

require './test/fake'

Log.setup("Main", "effects")

core = CoreWrapper.new

stomach = core.create(:stomach)

# Test various things to watch them dissolve in stomach acid
flesh = core.create(:flesh, {:position => stomach})

Message.dispatch(core, :tick)
Message.dispatch(core, :tick)
Message.dispatch(core, :tick)
Message.dispatch(core, :tick)
