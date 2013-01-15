require './util/log'

module Composition
    class << self
        def at_creation(instance, params)
            instance.set_property(:weight, 0)
            instance.initial_composure(params)
        end

        def at_destruction(instance)
            Log.debug("Destroying composition #{instance.monicker}", 7)
            [:internal, :incidental, :external].each do |key|
                switch = "preserve_#{key}".to_sym
                if instance.class_info(switch)
                    # Drop these components at the location where this object is
                    instance.get_property(key).each do |component|
                        Log.debug("Dropping #{component.monicker} at #{instance.absolute_position.name}")
                        component.move_to(instance.absolute_position)
                    end
                else
                    Log.debug("#{instance.monicker} does not preserve #{key} components")
                end
            end
        end
    end

    def initial_composure(params)
        [:internal, :incidental, :external].each do |comp_type|
            components           = @properties[comp_type].dup
            already_created      = components.select { |component| BushidoObject === component }
            to_be_created        = components - already_created
            @properties[comp_type] = already_created

            to_be_created.each do |component|
                @core.db.create(@core, component, params.merge(
                    :position      => self,
                    :position_type => comp_type
                ))
            end
        end
    end

    # This is used by various at_creation methods to assemble objects sans-sanity checks
    def add_object(object, type=:internal)
        Log.debug("Assembling #{monicker} - #{object.monicker} added to list of #{type} parts", 6)
        raise "Invalid composition type: #{type}" unless [:internal, :incidental, :external].include?(type)
        @properties[type] << object
        add_weight(object)
        add_value(object) unless type == :internal
    end

    def insert_object(object)
        raise "#{monicker} is not a container" unless @core.db.info_for(self.type, :is_container)
        # TODO - check for relative size / max carry number / other restrictions
        Log.debug("Inserting #{object.monicker} into #{monicker}", 6)
        @properties[:internal] << object
        add_weight(object)
    end

    def attach_object(object)
        # TODO - check for relative size / max carry number / other restrictions
        Log.debug("Attaching #{object.monicker} to #{monicker}", 6)
        @properties[:external] << object
        add_weight(object)
        add_value(object)
    end

    def remove_object(object)
        Log.debug("Removing #{object.monicker} from #{monicker}", 6)
        if @properties[:internal].include?(object)
            @properties[:internal].delete(object)
            remove_weight(object)
        elsif @properties[:external].include?(object)
            @properties[:external].delete(object)
            remove_weight(object)
            remove_value(object)
        elsif @properties[:incidental].include?(object)
            remove_weight(object)
            remove_value(object)
        else
            raise "No matching object found"
        end
    end

    def internal_objects(&block)
        select_objects(:internal, false, &block)
    end

    def external_objects(&block)
        select_objects(:external, false, &block)
    end

    def select_objects(type, recursive=false, depth=5, &block)
        type = Array(type)
        list = []
        type.each do |type|
            @properties[type].each do |obj|
                next if block_given? && !block.call(obj)
                list << obj
                if recursive && obj.is_type?(:composition) && depth > 0
                    list += obj.select_objects(type, recursive, depth - 1, &block)
                end
            end
        end
        list
    end

    private
    def add_weight(object)
        @properties[:weight] += object.weight
    end

    def remove_weight(object)
        @properties[:weight] -= object.weight
    end

    def add_value(object)
        @properties[:value] += object.value
    end

    def remove_value(object)
        @properties[:value] -= object.value
    end
end
