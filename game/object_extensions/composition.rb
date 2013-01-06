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

        def at_destruction(instance)
            instance.instance_exec do
                Log.debug("Destroying #{@type}")
                [[:preserve_external, :external], [:preserve_internal, :internal]].each do |switch, key|
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

    def add_object(object)
        raise "#{@name || @type} is not a container" unless @properties[:is_container]
        Log.debug("Inserting #{object.name || object.type} into #{@name || @type}")
        @properties[:internal] << object
    end

    def attach_object(object)
        Log.debug("Attaching #{object.name || object.type} to #{@name || @type}")
        @properties[:external] << object
    end

    def remove_object(object)
        Log.debug("Removing #{object.name || object.type} from #{@name || @type}")
        if @properties[:internal].include?(object)
            @properties[:internal].delete(object)
        elsif @properties[:external].include?(object)
            @properties[:external].delete(object)
        else
            raise "No matching object found inside #{@name || @type}"
        end
    end
end
