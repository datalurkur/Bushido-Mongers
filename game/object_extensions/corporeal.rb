require './util/log'
require './util/exceptions'

module Corporeal
    class << self
        def at_creation(instance, params)
            instance.create_body
            instance.start_listening_for(:unit_attacks)
        end

        def at_message(instance, message)
            case message.type
            when :unit_attacks
                if message.defender == instance
                    Log.debug("#{instance.monicker} is being attacked!", 7)

                    # TODO - extract damage from attacker, tool, etc.
                    damage = 1

                    target_part = if rand() > 0.5
                        # Target a random body part
                        instance.external_body_parts.rand
                    else
                        # Not a targeted shot
                        nil
                    end
                    instance.damage(damage, message.attacker, target_part)
                end
            end
        end
    end

    def create_body
        unless get_property(:incidental).empty?
            Log.error("Body created twice for #{monicker}")
            return
        end
        body_type = class_info(:body_type)
        @core.create(body_type, {
            :relative_size => get_property(:size),
            :position      => self,
            :position_type => :incidental
        })
        @total_hp = all_body_parts.map(&:hp).inject(0, &:+)

        # If this has multiple values, I don't know what the fuck we're doing
        # That would mean that this corporeal thing has multiple independent bodies
        # How do you even describe such a thing?
        raise(UnexpectedBehaviorError, "Multiple independent bodies provided for #{monicker}.") if get_property(:incidental).size > 1
    end

    def all_body_parts(type = [:internal, :external])
        get_property(:incidental).collect do |body|
            body.select_objects(type, true) { |obj| obj.is_type?(:body_part) }
        end.flatten
    end

    def external_body_parts
        all_body_parts(:external)
    end

    def internal_body_parts
        get_property(:incidental) + all_body_parts(:internal)
    end

    def damage(amount, attacker, target=nil)
        target ||= get_property(:incidental).rand
        target.set_property(:hp, target.hp - amount)
        @total_hp -= amount
        if target.hp <= 0
            if get_property(:incidental).include?(target)
                Log.debug("Destroying body of #{monicker}")
                @core.flag_for_destruction(self, attacker)
            end
            @core.flag_for_destruction(target, attacker)
        end
    end
end
