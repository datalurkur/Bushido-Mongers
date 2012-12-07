=begin
    Zone Keyword:
        :sanctuary
    Effect:
        -The Zone is deemed a "safe zone" for players
        -Contains merchant NPCs to buy / sell
        -Contains protector NPCs whose job it is to keep monsters out and keep the peace
        -Contains safe havens for players to rest and recuperate (unless another player might choose to poison them, etc)
=end

=begin
    Discussion:
        We need to hammer out how NPCs will be tied with Zone keywords.  Some possibilities:
        1) Zones dictate what NPCs they can spawn
            Problems:
                -Quickly becomes overloaded with keywords
                    Possible Solution: Also allow NPC classes (Monster, Guard, Merchant, Unique, etc) to be specified
        2) NPCs dictate what Zones they can spawn in
            Problems:
                -Makes Zones search through the entire NPC list to see what NPCs are suitable for the location
                -Forces NPCs to have knowledge of Zone keywords
        3 ) Some combination of #'s 1 and 2
            -Zones filter first, indicating as generally as possible which NPCs they want to spawn there
            -Secondarily, some kind of keyword matching comes into play, where an NPC can specify that it spawns in zones that have certain keywords
    AJEAN: For now, I'm assuming #3, since it has the most flexibility
=end

Zone.describe(:sanctuary, {
    :always_contains => [:haven],
    :may_contain     => [:tavern, :inn],
    :never_contains  => [:dungeon],
    :always_spawns   => [:peacekeeper],
    :may_spawn       => [NPC::Merchant],
    :never_spawns    => [NPC::Monster],
})

=begin
    NPC Keyword:
        :peacekeeper
    Effect:
        This NPC "keeps the peace" by attacking anyone who starts a fight with another player; it's important to note that the logic used to detect who starts a fight with who will have to exclude other peacekeeper NPCs attacking the instigators (otherwise, this is a group that's just going to wind up slaughtering each other if someone so much as throws a rock at one of them).
=end

NPC.describe(:peacekeeper, {
    :required_keywords => [], # We would put :haven here if we wanted peacekeepers to *only* spawn in havens
    :rejected_keywords => [:dungeon], # Places this NPC will *never* spawn
    :reaction          => Proc.new do |message|
        if message.type == :attack
=begin
            Here we would insert some logic that detects
                -Whether this NPC is already fighting
                -Whether this attack was the first in a fight
                -Whether the attacker is also a peacekeeper
            and decides to fight based on the results
=end
            raise NotImplementedError
        end
    end,
})
