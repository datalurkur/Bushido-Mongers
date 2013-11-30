require './messaging/positional_message'
Message = PositionalMessage
require './messaging/message_defs'

require './test/fake'

Log.setup("Main", "effects")

def do_command(core, agent, command)
	params = core.words_db.decompose_command(command)
	params = params.merge(:agent => agent)

	Commands.stage(core, params)
	Commands.do(core, params)
end

$core = FakeCore.new

room     = $core.create(FakeRoom)
object   = $core.create(:katana, :randomize => true, :position => room)
receiver = $core.create_npc(:human, :position => room)
player   = $core.create(:dwarf, :position => room)

Log.debug(player)

quest = $core.create(:quest, Quest.object_delivery_quest(object, receiver))

do_command($core, player, "get katana")
do_command($core, player, "give katana to human")