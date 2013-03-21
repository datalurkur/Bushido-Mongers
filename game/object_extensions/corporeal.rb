require './util/log'
require './util/exceptions'
require './game/transforms'

module Corporeal
    class << self
        def at_creation(instance, params)
            instance.create_body
        end
    end

    def create_body
        unless container_contents(:incidental).empty?
            Log.error("Body created twice for #{monicker}")
            return
        end
        body_type = class_info[:body_type]
        @core.create(body_type, {
            :relative_size => @properties[:size],
            :position      => self,
            :position_type => :incidental
        })
        @properties[:total_hp] = all_body_parts.collect { |p| p.properties[:hp] }.inject(0, &:+)

        # If this has multiple values, I don't know what the fuck we're doing
        # That would mean that this corporeal thing has multiple independent bodies
        # How do you even describe such a thing?
        raise(UnexpectedBehaviorError, "Multiple independent bodies provided for #{monicker}.") if container_contents(:incidental).size > 1
    end

    def all_body_parts(type = [:internal, :external])
        container_contents(:incidental) +
        container_contents(:incidental).map do |body|
            body.select_objects(type, true) { |obj| obj.is_type?(:body_part) }
        end.flatten
    end

    def external_body_parts
        all_body_parts(:external)
    end

    def internal_body_parts
        all_body_parts(:internal)
    end

    def damage(amount, attacker, target=nil)
        # If a body part (target) isn't specified, just damage the body.
        target ||= container_contents(:incidental).rand
        target.properties[:hp] -= amount
        @properties[:total_hp] -= amount
        if target.properties[:hp] <= 0
            # If the whole body is destroyed, the corporeal (spirit)
            # dies, and the body will hit the floor.
            if container_contents(:incidental).include?(target)
                Log.debug("Destroying #{monicker}!")
                # FIXME - Eventualy, this is what converts the Corporeal object to a corpse
                Transforms.transform(self, :death)
                @core.flag_for_destruction(self, attacker)
            else
                @core.flag_for_destruction(target, attacker)
            end
        end
    end
end
