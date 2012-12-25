require 'ai/basic_behavior'

module NpcBehavior
    class << self
        def at_creation(instance, params)
            instance.set_behavior(params[:behavior] || :random_attack_and_move)
        end

        def at_message(instance, message)
            case message.type
            when :tick
                instance.behavior.act(instance)
                return true
            end
            return false
        end
    end

    attr_accessor :behavior

    def set_behavior(behavior)
        @behavior = BehaviorSet.create(behavior)
    end

    def do_command(command, args)
        begin
            cmd_obj = @core.db.create(command, args)
        rescue Exception => e
            Log.debug(["NPC failed to create command object of type #{command}", args, e.message])
        end

        cmd_obj.on_command unless cmd_obj.nil?
    end
end
