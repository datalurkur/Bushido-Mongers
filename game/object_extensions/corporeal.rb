require './util/log'

module Corporeal
    class << self
        def at_message(instance, message)
            instance.instance_exec {
                case message.type
                when :unit_attacks
                    if message.defender == self
                        Log.debug("#{monicker} is being attacked!")

                        # TODO - extract damage from attacker, tool, etc.
                        damage = 1
                        rand_part = external_body_parts.rand
                        damage(rand_part, damage, message.attacker)
                        damage(self.body, damage, message.attacker)
                    end
                end
            }
        end

        def at_creation(instance, params)
            instance.instance_exec {
                body_type = @core.db.info_for(@type, :body_type)
                body      = @core.db.create(@core, body_type, {:relative_size => @properties[:size]})
                @properties[:body]   = body
                @properties[:weight] = all_body_parts.map(&:weight).inject(0, &:+)
                @properties[:body].set_property(:hp, all_body_parts.map(&:hp).inject(0, &:+))
            }
        end

        def at_destruction(instance)
            # Drop the body
            instance.instance_exec {
                @properties[:body].set_position(@position)
            }
        end
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
            part.destroy
            if part == self.body
                target = self
                self.destroy
            else
                target = part
            end
            Message.dispatch(@core, :object_destroyed, :agent => attacker, :position => self.position, :target => target)
        end
    end
end
