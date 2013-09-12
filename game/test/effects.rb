require './messaging/positional_message'
Message = PositionalMessage
require './messaging/message_defs'

require './test/fake'

Log.setup("Main", "effects")

core = FakeCore.new


# STOMACH TEST
# ============
stomach = core.create(:stomach)

# Test various things to watch them dissolve in stomach acid
flesh = core.create(:flesh, {:position => stomach})

4.times { |i|
    Log.debug("(#{i}) Acid burns!")
    Message.dispatch(core, :tick)
}

# ORB OF DEATH TEST
# =================
fake_room = core.create(FakeRoom)

human     = core.create_npc(:human, {:position => fake_room})
orb       = core.create(:orb_of_death)
human.stash(orb)

giant     = core.create_npc(:giant, {:position => fake_room})
backpack  = core.create(:backpack, {:randomize => true})
human.set_position(backpack, :internal)
giant.stash(backpack)

Log.debug("Orb's position : #{orb.relative_position.monicker} / #{orb.possessive_position.monicker} / #{orb.absolute_position.monicker}")

25.times { |i|
    possessor = orb.possessive_position
    Log.debug("(#{i}) Death draws nearer for #{possessor ? possessor.monicker : "no-one, as the orb lies dormant"}")
    Message.dispatch(core, :tick)
}
