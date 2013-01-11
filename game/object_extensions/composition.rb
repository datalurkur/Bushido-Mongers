require './util/log'

module Composition
    class << self
        def at_creation(instance, params)
            instance.instance_exec do
                [:internal, :incidental, :external].each do |comp_type|
                    components = @properties[comp_type].dup
                    @properties[comp_type] = []
                    components.each do |component|
                        @core.db.create(@core, component, params.merge(:position => instance, :position_type => comp_type))
                    end
                    @properties[:weight] += @properties[comp_type].inject(0) { |s,p| s + p.weight }
                end

                @properties[:value] += @properties[:incidental].inject(0) { |s,p| s + p.value }
            end
        end

        def at_destruction(instance)
            instance.instance_exec do
                Log.debug("Destroying #{@type}")
                [:internal, :incidental, :external].each do |switch, key|
                    switch = "preserve_#{key}".to_sym
                    if class_info(switch)
                        # Drop these components at the location where this object is
                        @properties[key].each do |component|
                            component.move(@position)
                        end
                    end
                end
            end
        end
    end

    # This is used by various at_creation methods to assemble objects sans-sanity checks
    def add_object(object, type=:internal)
        Log.debug("Assembling #{monicker} - #{object.monicker} added to list of #{type} parts", 6)
        @properties[type] << object
    end

    def insert_object(object)
        raise "#{monicker} is not a container" unless @core.db.info_for(self.type, :is_container)
        # TODO - check for relative size / max carry number / other restrictions
        Log.debug("Inserting #{object.monicker} into #{monicker}", 6)
        @properties[:internal] << object
    end

    def attach_object(object)
        # TODO - check for relative size / max carry number / other restrictions
        Log.debug("Attaching #{object.monicker} to #{monicker}", 6)
        @properties[:external] << object
    end

    def remove_object(object)
        Log.debug("Removing #{object.monicker} from #{monicker}", 6)
        if @properties[:internal].include?(object)
            @properties[:internal].delete(object)
        elsif @properties[:external].include?(object)
            @properties[:external].delete(object)
        else
            raise "No matching object found"
        end
    end

    def internal_objects
        select_objects(:internal, false)
    end

    def external_objects
        select_objects(:external, false)
    end

    private
    def select_objects(type, recursive=false, &block)
        list = []
        @properties[type].each do |obj|
            if block_given?
                list << obj if block.call(obj)
            else
                list << obj
            end
        end
        list
    end
end
