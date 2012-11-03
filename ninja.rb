require 'message'
require 'util'
require 'log'

class Ninja < TypedConstructor
    attr_accessor :location, :queued_action, :owner
    def initialize(name,owner,start)
        type = super(name)

        @archetype         = type[:archetype]
        @hitpoints         = type[:hitpoints]

        @reincarnating     = false

        @owner             = owner
        @location          = start
        @previous_location = start
        @queued_action     = nil
        @queued_move       = nil

        Message.register_listener(self, Message::SetNinjaAction)
        Message.register_listener(self, Message::SetNinjaMove)
        Message.register_listener(self, Message::UnitMoves)
        Message.register_listener(self, Message::UnitAttacks)
        Message.register_listener(self, Message::Intel)

        self
    end

    def reincarnating?; @reincarnating; end
    def revive(location); @reincarnating = false; @location = location; end

    def update
        return if reincarnating?

        if @queued_move
            move_through(@queued_move)
            @queued_move = nil
        else
            @previous_location = location
        end
        if @queued_action
            @queued_action.call(location,self)
            @queued_action = nil
        end
    end

    def parse_message(message)
        case message
        when Message::SetNinjaAction
            if message.owner == owner
                debug("#{owner}:#{name} will #{message.action_name} at #{location.name}")
                @queued_action = message.action
            end
        when Message::SetNinjaMove
            if message.owner == owner
                debug("#{owner}:#{name} will move to #{message.portal.dest.name} through #{message.portal.name}")
                @queued_move = message.portal
            end
        when Message::UnitMoves
            return if message.agent == self

            visible_areas = [observed_current, observed_previous]

            portal = (@archetype != :clever && message.portal.hidden) ? message.portal        : nil
            source = (visible_areas.include?(message.portal.source))  ? message.portal.source : nil
            dest   = (visible_areas.include?(message.portal.dest))    ? message.portal.dest   : nil

            if visible_areas.include?(message.portal.source) || visible_areas.include?(message.portal.dest)
                debug("#{name} observes #{message.agent.name} moving in some way within #{visible_areas.collect(&:name).inspect}")
                Message.send(Message::News.move(owner,self,message.agent,source,dest,portal))
            end
        when Message::UnitAttacks
            return unless message.target == self
            if rand() < dodge_chance
                debug("#{owner}:#{name} dodges!")
                Message.send(Message::News.new([owner,message.agent.owner],"#{name} evades #{message.agent.name}'s attack"))
            elsif rand() < block_chance
                debug("#{owner}:#{name} blocks!")
                Message.send(Message::News.new([owner,message.agent.owner],"#{name} blocks #{message.agent.name}'s attack"))
            else
                damage = message.agent.damage
                @hitpoints -= damage
                Message.send(Message::News.new([self.owner,message.agent.owner],"#{name} is hit by #{message.agent.name}'s attack for #{damage} damage"))
                if @hitpoints <= 0
                    @reincarnating = true
                    Message.send(Message::UnitDies.new(self,message.agent))
                end
            end
        when Intel
            return if message.agent == self

            if [observed_previous, observed_current].include?(message.location)
                debug("#{name} observes #{message.agent.name} performing #{message.action} at #{message.location}")
                Message.send(Message::News.action(owner,self,message.agent,message.action,message.location,"witnesses"))
            elsif message.location.castle == location.castle
                if rand() < intel_gathering_chance
                    debug("#{name} catches wind of #{message.agent.name} performing #{message.action} at #{message.location}")
                    Message.send(Message::News.action(owner,self,message.agent,message.action,message.location,intel_gathering_means))
                else
                    debug("#{name} fails to gather intel: #{message.agent.name} performing #{message.action} at #{message.location}")
                end
            end
        end
    end

    def get_moves
        location.portals.select { |portal| can_enter?(portal) }
    end

    def get_actions
        location.get_actions_for(self)
    end

    def move_through(portal)
        (raise "#{portal.name} not present at #{location.name}") unless (location.portals.include?(portal))
        @previous_location = location
        location = portal.dest
        Message.send(Message::UnitMoves.new(self,portal))
    end

private
    def intel_gathering_means
        case @archetype
        when :clever; "persuases a commoner into elaborating"
        when :agile;  "catches wind of a conversation detailing"
        when :strong; "tortures a peasant into revealing"
        end
    end

    def intel_gathering_chance
        case @archetype
        when :clever; 0.5
        when :agile;  0.4
        when :strong; 0.3
        end
    end

    def dodge_chance
        case @archetype
        when :agile;  0.3
        when :clever; 0.2
        when :strong; 0.1
        end
    end

    def block_chance
        case @archetype
        when :strong; 0.3
        when :clever; 0.2
        when :agile;  0.1
        end
    end

    def damage
        case @archetype
        when :strong; rand(12)
        when :clever; rand(8)+2
        when :agile;  rand(4)+4
        end
    end

    def observed_previous
        @queued_move.nil? ? @previous_location : location
    end

    def observed_current
        @queued_move.nil? ? location : @queued_move.dest
    end

    def can_enter?(portal)
        if location.owner != owner
            (return false) if (portal.hidden && @archetype != :clever)
            (return false) if (portal.fortified && @archetype != :strong)
        end 
        (return false) if (portal.wrongway && @archetype != :agile)
        return true
    end
end

Ninja.describe({
    :name        => "Kenji Scrimshank",
    :description => "a shadowy figure wearing an eyepatch",
    :archetype   => :agile,
    :hitpoints   => 30
})
Ninja.describe({
    :name        => "Hamtaro Oishii",
    :description => "a jolly, round creature whose smile betrays little",
    :archetype   => :clever,
    :hitpoints   => 40
})
