module Composition
    class << self
        def at_creation(instance, context, params)
            instance.instance_exec do
                [:internal, :incidental, :external].each do |comp_type|
                    components = @properties[comp_type].collect do |component|
                        @core.db.create(@core, component, context, params)
                    end
                    @properties[comp_type] = components
                    @properties[:weight] += @properties[comp_type].inject(0) { |s,p| s + p.weight }
                end
                @properties[:value] += @properties[:incidental].inject(0) { |s,p| s + p.value }
            end
        end

        def at_destruction(instance, context)
            instance.instance_exec do
                Log.debug("Destroying #{@type}")
                [:internal, :incidental, :external].each do |switch, key|
                    switch = "preserve_#{key}".to_sym
                    if class_info(switch)
                        # Drop these components at the location where this object is
                        @properties[key].each do |component|
                            context[:position].add_object(component)
                        end
                    end
                end
            end
        end
    end

    def add_object(object)
        # TODO - this should return to the client the message that this action is not possible
        raise "#{monicker} is not a container" unless @core.db.info_for(self.type, :is_container)
        # TODO - check for relative size / max carry number / other restrictions
        Log.debug("Inserting #{object.monicker} into #{monicker}")
        @properties[:internal] << object
    end

    def attach_object(object)
        # TODO - check for relative size / max carry number / other restrictions
        Log.debug("Attaching #{object.monicker} to #{monicker}")
        @properties[:external] << object
    end

    def remove_object(object)
        Log.debug("Removing #{object.monicker} from #{monicker}")
        if @properties[:internal].include?(object)
            @properties[:internal].delete(object)
        elsif @properties[:external].include?(object)
            @properties[:external].delete(object)
        else
            raise "No matching object found"
        end
    end
end
