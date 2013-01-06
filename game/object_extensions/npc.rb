require 'ai/basic_behavior'
require 'game/commands'

module NpcBehavior
    class << self
        def at_creation(instance, params)
            instance.instance_exec {
                set_behavior(params[:behavior] || :random_attack_and_move)
                Message.register_listener(@core, :core, self)
            }
        end

        def at_message(instance, message)
            case message.type
            when :tick
                instance.behavior.act(instance)
                return true
            end
            return false
        end

        def at_destruction(instance, context)
            instance.instance_exec {
                Message.unregister_listener(@core, :core, self)
            }
        end
    end

    attr_accessor :behavior

    def set_behavior(behavior)
        @behavior = BehaviorSet.create(behavior)
    end

    def do_command(command, args)
        begin
            Commands.do(@core, command, args)
        rescue Exception => e
            Log.error(["NPC failed to perform command #{command}", args, e.message, e.backtrace])
        end
    end
end
