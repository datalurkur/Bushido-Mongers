class Message
    class << self
        def listeners(message_class)
            @listeners ||= {}
            @listeners[message_class] ||= []
        end

        def register_listener(listener, message_class)
            self.listeners(message_class) << listener
            self.listeners(message_class).uniq!
        end

        def send(message)
            self.listeners(message.class).each do |listener|
                begin
                    debug("Dispatching #{message.class} message to #{listener.class}",4)
                    listener.parse_message(message)
                rescue Exception => e
                    debug("#{listener.class} failed to parse message #{message.class} : #{e.message}")
                    debug(e.backtrace)
                end
            end
        end
    end

    def initialize(data={}); @data=data; self; end
    #def [](index); @data[index]; end
    def method_missing(name,*args,&block); @data[name]; end

    # Messages that the server cares about
    class NewPlayer < Message
        def initialize(player,castle,ninja); super(:player=>player, :castle=>castle, :ninja=>ninja); end
    end
    class SetPlayerReady < Message
        def initialize(player,state); super(:player=>player, :state=>state); end
    end

    # Messages that clients care about
    class PlayerRejected < Message
        def initialize(player,reason); super(:player=>player, :reason=>reason); end
    end
    class PlayerJoins < Message
        def initialize(player,castle,ninja); super(:player=>player, :castle=>castle, :ninja=>ninja); end
    end
    class PlayerResigns < Message
        def initialize(player); super(:player=>player); end
    end
    class PlayerDefeated < Message
        def initialize(player,reason); super(:player=>player, :reason=>reason); end
    end
    class RegistrationBegins < Message; end
    class GamePending < Message; end
    class GameStarts < Message; end
    class NextRound < Message; end
    class GameEnds < Message
        def initialize(winner); super(:winner=>winner); end
    end

    # Messages that game state cares about
    # Rooms also care about this one
    class UnitMoves < Message
        def initialize(agent,portal); super(:agent=>agent, :portal=>portal); end
    end
    class UnitAttacks < Message
        def initialize(agent,target); super(:agent=>agent, :target=>target); end
    end
    class UnitDies < Message
        def initialize(agent,slayer); super(:agent=>agent, :slayer=>slayer); end
    end
    class UnitReincarnates < Message
        def initialize(agent,location); super(:agent=>agent, :location=>location); end
    end
    class Intel < Message
        def initialize(agent,action,location,means); super(:agent=>agent, :action=>action, :location=>location); end
    end
    # Messages ninjas care about
    class SetNinjaMove < Message
        def initialize(owner,portal); super(:owner=>owner, :portal=>portal); end
    end
    class SetNinjaAction < Message
        def initialize(owner,action_name); super(:owner=>owner, :action_name=>action_name); end
    end

    # Messages players care about
    class News < Message
        def initialize(recipients,message)
            rcpts = unless Array === recipients
                [recipients]
            else
                recipients
            end
            super(:recipients=>rcpts, :message=>message)
        end
        def self.move(recipient,witness,agent,source,dest,portal)
            message="FIXME"
            News.new(recipient,message)
        end
        def self.action(recipient,witness,agent,action,location,name)
            message="FIXME"
            News.new(owner,message)
        end
    end
end

