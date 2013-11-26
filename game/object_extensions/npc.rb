require './ai/behavior_set'
require './ai/basic_behavior'
require './game/commands'

module NpcBehavior
    class << self
        def listens_for(i); [:tick]; end

        def pack(instance)
            {:behavior => instance.behavior_type}
        end

        def unpack(core, instance, raw_data)
            raise(MissingProperty, "NpcBehavior data corrupted (behavior)") unless raw_data.has_key?(:behavior)
            instance.set_behavior(raw_data[:behavior])
        end

        def at_message(instance, message)
            case message.type
            when :tick
                instance.behavior.act(instance)
            end
        end
    end

    attr_reader :behavior_type, :behavior

    def set_behavior(behavior)
        @behavior_type = behavior
        @behavior      = BehaviorSet.create(behavior)
    end

    def do_command(args)
        begin
            Commands.do(@core, args.merge(:agent => self))
        rescue Exception => e
            Log.error(["#{monicker} failed to perform command #{args[:command]}", e.message, e.backtrace])
        end
    end
end
