require 'game/mob'
require 'ai/basic_behavior'
require 'raws/db'

class NPC < BushidoObject
    include Mob

    attr_reader :name

    def initialize(core, name, type, args={})
        @name = name
        @core = core

        set_position(args[:position]) if args[:position]
        args.delete(:position)

        super(core, type, args)


        @behavior = BehaviorSet.create(:random_attack_and_move)

        core.add_npc(self)
    end

    def set_behavior(behavior)
        @behavior = BehaviorSet.create(behavior)
    end

    def tick
        @behavior.act(self)
    end

    def attack(target)
        Log.debug("#{name} attacking #{target.name}")
        Message.dispatch(@core, :unit_attacks, {
            :attacker      => self,
            :defender      => target,
            :chance_to_hit => "FIXME",
            :damage        => "FIXME"
        })
    end

    def process_message(message)
        case message.type
        when :tick
            tick
        when :unit_attacks
            if self == message.defender
                Log.debug("NPC #{@name} is attacked by #{message.attacker}")
            end
        when :unit_moves
        else
            Log.debug("NPC #{@name} ignoring #{message.type}")
        end
    end
end
