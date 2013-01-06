module Composition
    class << self
        def at_creation(instance, params)
            instance.instance_exec do
                [:internal, :external].each do |comp_type|
                    components = @properties[comp_type].collect do |component|
                        @core.db.create(@core, component, params)
                    end
                    @properties[comp_type] = components
                    @properties[:weight] += @properties[comp_type].inject(0) { |s,p| s + p.weight }
                end
            end
        end

        def at_destruction(instance, context)
            instance.instance_exec do
                Log.debug("Destroying #{@type}")
                [[:preserve_external, :external], [:preserve_internal, :internal]].each do |switch, key|
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
        raise "#{monicker} is not a container" unless @properties[:is_container]
        Log.debug("Inserting #{object.monicker} into #{monicker}")
        @properties[:internal] << object
    end

    def attach_object(object)
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
