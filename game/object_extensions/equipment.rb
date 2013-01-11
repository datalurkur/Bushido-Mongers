=begin
16:54 <@datalurkur> I think an Equipment module is in order.
16:54 <@datalurkur> And basically this describes a creature that's intelligent enough to use tools.
16:55 <@datalurkur> With this will come a list of slots per body type that can hold equipment, and the types of equipment it can hold.
16:55 <@datalurkur> And the inventory will just be a list of equipment attached to slots along with the contents of any of that equipment that happens to be a container.
=end

module Equipment
    class << self
        def at_creation(instance, params)
            Log.debug(params)
            instance.instance_exec {
                Log.debug(all_body_parts)
                external_body_parts.each do |part|
                    if part.has_property?(:can_equip) && !part.can_equip.empty?
                        rand_type = @core.db.random(part.can_equip.rand)

                        # Pick random component type
                        creation_hash = {}
                        components = @core.db.info_for(rand_type, :required_components)
                        components.map! do |comp|
                            @core.db.create(@core, @core.db.random(comp))
                        end

                        creation_hash[:components] = components
                        
                        creation_hash[:quality] = :standard

                        # FIXME: adjust size based on size of self
                        new_equip = @core.db.create(@core, rand_type, creation_hash)
                        part.attach_object(new_equip)
                    end
                end
            }

        end

        def at_destruction(instance)
            # drop equipment on death, or leave it on the body to be pulled off?
        end
    end

    def equip
        # TODO
    end
end