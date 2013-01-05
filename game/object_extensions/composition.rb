module Composition
    class << self
        def at_creation(instance, params)
            instance.instance_exec do
                [:internal_components, :external_components].each do |comp_type|
                    components = @properties[comp_type].collect do |component|
                        @core.db.create(@core, component, params)
                    end
                    @properties[comp_type] = components
                    @properties[:weight] += @properties[comp_type].inject(0) { |s,p| s + p.weight }
                end
            end
        end

        def at_destruction(instance)
            instance.instance_exec do
                Log.debug("Destroying #{@type}")
                [[:preserve_external, :external_components], [:preserve_internal, :internal_components]].each do |switch, key|
                    if class_info(switch)
                        # FIXME - Items need locations, apparently
                        # Drop these components at the location where this object is
                        @properties[key].each do |component|
                            Log.debug("Dropping #{component.type}")
                        end
                    end
                end
            end
        end
    end
end
