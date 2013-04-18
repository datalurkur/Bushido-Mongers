require './messaging/positional_message'
Message = PositionalMessage
require './messaging/message_defs'

require './test/fake'

Log.setup("Main", "effects")

core = CoreWrapper.new


# STOMACH TEST
# ============
stomach = core.create(:stomach)

# Test various things to watch them dissolve in stomach acid
flesh = core.create(:flesh, {:position => stomach})

2.times { Message.dispatch(core, :tick) }

# ORB OF DEATH TEST
# =================
fake_room = FakeRoom.new
human     = core.populations.create_agent(:human, false, {:position => fake_room})
orb       = core.create(:orb_of_death)
human.stash(orb)
Log.debug("Orb's position : #{orb.relative_position.monicker} / #{orb.possessive_position.monicker} / #{orb.absolute_position.monicker}")

12.times { Message.dispatch(core, :tick) }
