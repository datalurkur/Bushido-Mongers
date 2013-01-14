require './util/log'

module Corporeal
    class << self
        def at_creation(instance, params)
            instance.create_body
            instance.start_listening_for(:core)
        end

        def at_message(instance, message)
            case message.type
            when :unit_attacks
                if message.defender == instance
                    Log.debug("#{instance.monicker} is being attacked!")

                    # TODO - extract damage from attacker, tool, etc.
                    damage = 1
                    rand_part = instance.external_body_parts.rand
                    instance.damage(rand_part,     damage, message.attacker)
                    instance.damage(instance.body, damage, message.attacker)
                end
            end
        end

        def at_destruction(instance)
            instance.drop_body
        end
    end

    def create_body
        if @properties[:body]
            Log.error("Body created twice for #{monicker}")
            return
        end
        body_type = class_info(:body_type)
        body      = @core.db.create(@core, body_type, {:relative_size => @properties[:size]})
        @properties[:body]   = body
        @properties[:weight] = all_body_parts.map(&:weight).inject(0, &:+)

        @total_hp = all_body_parts.map(&:hp).inject(0, &:+)
    end

    def drop_body
        @properties[:body].set_position(@position) if @properties[:body]
    end

    def all_body_parts(type = [:internal, :external])
        selector = Proc.new { |obj| obj.is_type?(:body_part) }
        @properties[:body].select_objects(type, true, &selector)
    end

    def external_body_parts
        [@properties[:body]] + all_body_parts(:external)
    end

    def internal_body_parts
        all_body_parts(:internal)
    end

    def damage(part, damage, attacker)
        part.set_property(:hp, part.hp - damage)
        if part.hp <= 0
            if part == @properties[:body]
                Log.debug("Destroying body of #{monicker}")
                destroy(attacker)
            end
            part.destroy(attacker)
        end
    end
end
