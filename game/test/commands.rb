require './bushido'
require './util/traps'
require './util/cfg_reader'
require './net/lobby_bypass_client'
require './test/fake'

Log.setup("Main", "command_test")

def do_command(core, agent, command)
    params = core.words_db.decompose_command(command).merge(:agent => agent)

    Commands.stage(core, params)
    Commands.do(core, params)

    Log.debug(Descriptor.create_report(:act_staged, core.words_db, params.merge(:observer => agent, :speaker => :game)))
end

$core = FakeCore.new

room     = $core.create(FakeRoom)
           $core.create(:chest, :position => room, :randomize => true)
           $core.create(:rock,  :position => room)
player   = $core.create(:dwarf, :position => room)

do_command($core, player, "look")
do_command($core, player, "open chest")
do_command($core, player, "look in chest")
do_command($core, player, "get rock")
do_command($core, player, "look self")
do_command($core, player, "inventory")
do_command($core, player, "drop rock")
