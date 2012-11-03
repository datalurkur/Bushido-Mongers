require 'decoration'
require 'portal'
require 'message'
require 'util'

class Room < TypedConstructor
    attr_reader :each_turn, :decorations, :occupants, :portals
    def initialize(name,castle=nil)
        type = super(name)

        @castle = castle

        @decorations = []
        if type[:decorations]
            type[:decorations].each do |size,number|
                @decorations.concat(number.downto(1).collect { Decoration.new(:size => size) })
            end
        end
        @actions   = (type[:actions] || {})
        @occupants = []
        @portals   = []

        Message.register_listener(self, Message::UnitMoves)

        self
    end

    def parse_message(message)
        case message
        when Message::UnitMoves
            if message.dest == self
                @occupants << message.agent
            elsif message.source == self
                @occupants.reject! { |i| i == message.agent }
            end
        end
    end

    def update
        self.instance_exec(@each_turn) unless @each_turn.nil?
    end

    def add_portal(portal); @portals << portal; end
    def path_to?(dest); @portals.select { |i| i.dest == dest }.size > 0; end
    #def patrol_to?(dest); @portals.select { |i| i.dest == dest && !i.hidden && !i.oneway }; end

    def owner; @castle.owner; end

    def all_actions(agent)
        fight_actions = {}

        # Determine if any fights can occur
        @occupants.each do |other|
            next if other == agent
            next if other.owner == agent.owner

            debug("#{agent.name} can attack #{other.name}",3)
            fight_actions["Attack #{other.name}"] = Proc.new { |agent|
                debug("#{agent.name} attacks #{other.name!}")
                Message.send(Message::UnitAttacks.new(agent,other))
            }
        end
        
        @actions.merge(fight_actions)
    end

    def get_actions_for(agent)
        action_list = self.all_actions(agent)
        action_list.keys.select do |key|
            (Hash === action_list[key] && action_list[key][:condition]) ? action_list[key][:condition].call(agent) : true
        end
    end

    def get_action(key)
        action = self.all_actions[key]
        (Hash === action) ? action[:execution] : action
    end
end

Room.describe({
    :name => "Gardens",
    :description => "an ornate garden filled with precious objects and permeated by meditative silence",
    :decorations => {
        :large  => 1,
        :normal => 2,
        :small  => 3
    },
    :actions => {
        "Meditate" => Proc.new { |agent| puts "#{agent.name} meditates in #{agent.location}" }
    }
})

Room.describe({
    :name => "Dojo",
    :description => "a traditional gym used by Samurai to hone their swordsmanship",
    :decorations => {
        :normal => 2
    },
    :actions => {
        "Hone Skills" => Proc.new { |agent| puts "#{agent.name} hones his skill in #{agent.location}" }
    }
})

Room.describe({
    :name => "Treasury",
    :description => "a building used for counting money and collecting taxes",
    :decorations => {
        :normal => 4
    },
    :actions => {
        "Steal Gold" => {
            :execution => Proc.new { |agent| puts "#{agent} steals gold from #{agent.location.owner}" },
            :condition => Proc.new { |agent| agent.owner != agent.location.owner }
        }
    },
    :each_turn => Proc.new { puts "#{self.owner} earns gold from the #{self.name}" }
})

Room.describe({
    :name => "Market",
    :description => "a bustling bazaar full of loud voices and pungent goods",
    :decorations => {
        :large => 3,
        :normal => 4,
        :small => 6
    },
    :actions => {
        "Buy Poison" => Proc.new { |agent| puts "#{agent} buys poison" }
    },
    :each_turn => Proc.new { puts "#{self.owner} earns gold from the #{self.name}" }
})

Room.describe({
    :name => "Borderlands",
    :description => "a vast land snarling with bamboo forests, placid pools, and hidden paths"
})
