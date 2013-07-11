require './game/managers/manager'

# So basically we're concerned with faction numbers, faction heirarchy, and faction wealth / power

=begin
Factions affect:
    Populations
        - Provide metadata to the population manager about how to spawn things
    Attitudes
        - Determine when two agents are enemies
    Quests
=end

class FactionManager < Manager
end
