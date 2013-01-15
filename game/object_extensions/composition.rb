require './util/log'

module Composition
    class << self
        def at_creation(instance, params)
            instance.set_property(:weight, 0)
            instance.initial_composure(params)
        end

        def at_destruction(instance)
            Log.debug("Destroying composition #{instance.monicker}", 7)
            instance.container_classes.each do |key|
                if instance.preserved_container_classes.include?(key)
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
        self.container_classes.each do |comp_type|
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
    # TODO - check for relative size / max carry number / other restrictions
    def add_object(object, type=:internal)
        Log.debug("Assembling #{monicker} - #{object.monicker} added to list of #{type} parts", 6)
        raise "Invalid composition type: #{type}" unless self.container_classes.include?(type)
        @properties[type] << object
        add_weight(object)
        add_value(object) if self.added_value_container_classes.include?(type)
    end

    # TODO - check for relative size / max carry number / other restrictions
    def insert_object(object)
        raise "Can't insert into #{type}" unless self.container_classes.include?(:internal)
        raise "#{monicker} is not a container." unless self.mutable_container_classes.include?(:internal)
        Log.debug("Inserting #{object.monicker} into #{monicker}", 6)
        @properties[:internal] << object
        add_weight(object)
    end

    # TODO - check for relative size / max carry number / other restrictions
    def attach_object(object)
        raise "Can't attach to #{type}" unless self.container_classes.include?(:external)
        Log.debug("Attaching #{object.monicker} to #{monicker}", 6)
        @properties[:external] << object
        add_weight(object)
        add_value(object)
    end

    # TODO - expand this for all container_classes
    def remove_object(object)
        Log.debug("Removing #{object.monicker} from #{monicker}", 6)
        self.container_classes.each do |comp_type|
            if @properties[comp_type].include?(object)
                remove_weight(object)
                remove_value(object) if self.added_value_container_classes.include?(type)
                return @properties[comp_type].delete(object)
            end
        end
        raise "No matching object #{object.monicker} found."
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
            next unless @properties[type]
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
        @properties[:weight] = (@properties[:weight] || 0) + object.weight
    end

    def remove_weight(object)
        @properties[:weight] -= object.weight
    end

    def add_value(object)
        @properties[:value] = (@properties[:value] || 0) + object.value
    end

    def remove_value(object)
        @properties[:value] -= object.value
    end
end
