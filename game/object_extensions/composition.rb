require './util/log'
require './util/exceptions'

module Composition
    class << self
        def at_creation(instance, params)
            instance.set_property(:weight, 0)
            instance.initial_composure(params)
        end

        def at_destruction(instance, destroyer, vaporize)
            return if vaporize

            Log.debug("Destroying composition #{instance.monicker}", 7)
            instance.container_classes.each do |key|
                if instance.preserved_container_classes.include?(key)
                    # Drop these components at the location where this object is
                    instance.get_property(key).each do |component|
                        Log.debug("Dropping #{component.monicker} at #{instance.absolute_position.name}", 6)
                        # Force the new position.
                        component.set_position(instance.absolute_position, :internal, true)
                    end
                    # All components set to a new location. Clear the local references.
                    instance.set_property(key, [])
                else
                    Log.debug("#{instance.monicker} does not preserve #{key} components", 8)
                end
            end
        end
    end

    def initial_composure(params)
        self.symmetric.each do |symmetric_part|
            unless container_classes.include?(symmetric_part[:container_class])
                Log.error("No container class #{symmetric_part[:container_class].inspect} found for #{monicker}")
                next
            end
            # FIXME - Generate symmetric part names
            symmetric_names = []

            symmetric_part[:count].times do |i|
                # FIXME - Actually use the symmetry class to assign names here
                symmetric_params = {
                    :position      => self,
                    :position_type => symmetric_part[:container_class],
                    :randomize     => true
                }
                @core.create(symmetric_part[:object_type], params.merge(symmetric_params))
            end
        end

        self.container_classes.each do |comp_type|
            raise(MissingProperty, "Container class #{comp_type} specified but not created.") if get_property(comp_type).nil?
            components           = get_property(comp_type).dup
            already_created      = components.select { |component| BushidoObject === component }
            to_be_created        = components - already_created
            set_property(comp_type, already_created)

            to_be_created.each do |component|
                @core.create(component, params.merge(
                    :position      => self,
                    :position_type => comp_type,
                    :randomize     => true
                ))
            end
        end
    end

    # HELPER FUNCTIONS for different composition types.
    # TODO - make generators for these functions.

    # This is used by various at_creation methods to assemble objects sans-sanity checks
    # TODO - check for relative size / max carry number / other restrictions
    def add_object(object, type=:internal)
        Log.debug("Assembling #{monicker} - #{object.monicker} added to list of #{type} parts", 6)
        _add_object(object, type, false)
    end

    # TODO - check for relative size / max carry number / other restrictions
    def insert_object(object)
        Log.debug("Inserting #{object.monicker} into #{monicker}", 6)
        _add_object(object, :internal)
    end

    # TODO - check for relative size / max carry number / other restrictions
    def attach_object(object)
        Log.debug("Attaching #{object.monicker} to #{monicker}", 6)
        _add_object(object, :external)
    end

    def wear(object)
        Log.debug("Equipping #{object.monicker} on #{monicker}", 6)
        _add_object(object, :worn)
    end

    def grasp(object)
        Log.debug("Grasping #{object.monicker} in #{monicker}", 6)
        _add_object(object, :grasped)
    end

    def remove_object(object)
        Log.debug("Removing #{object.monicker} from #{monicker}", 6)
        self.container_classes.each do |type|
            if get_property(type).include?(object)
                return _remove_object(object, type)
            end
        end
        raise(NoMatchError, "No matching object #{object.monicker} found.")
    end

    def full?(type=:internal)
        case type
        when :grasped
            get_property(type).size > 0
        when :worn
            get_property(type).size > 1
        else
            false
        end
    end

    def is_container?
        self.container_classes.include?(:internal)
    end

    def grasping_parts
        all_body_parts.select { |bp| bp.container_classes.include?(:grasped) }
    end

    def containers(type, recursive=true)
        select_objects(type, recursive) { |obj| cont.respond_to?(:is_container?) && cont.is_container? }
    end

    def grasped_objects(recursive=false, &block)
        select_objects(:grasped, recursive, &block)
    end

    def worn_objects(recursive=false, &block)
        select_objects(:worn, recursive, &block)
    end

    def internal_objects(recursive=false, &block)
        select_objects(:internal, recursive, &block)
    end

    def external_objects(recursive=false, &block)
        select_objects(:external, recursive, &block)
    end

    def select_objects(type, recursive=false, depth=5, &block)
        type = Array(type)
        list = []
        type.each do |type|
            next unless get_property(type)
            get_property(type).each do |obj|
                next if block_given? && !block.call(obj)
                list << obj
                if recursive && obj.is_type?(:composition) && depth > 0
                    list += obj.select_objects(type, recursive, depth - 1, &block)
                end
            end
        end
        list
    end

    def all_children
        self.container_classes.inject([]) do |i, cc|
            i + cc.inject([]) do |j, obj|
                j + [obj] + obj.is_type?(:composition) ? obj.all_children : []
            end
        end.flatten
    end

    private
    def _add_object(object, type, respect_mutable=true)
        raise(ArgumentError, "Invalid container class #{type}.") unless self.container_classes.include?(type)
        raise(ArgumentError, "Cannot modify #{type} composition of #{monicker}!") if respect_mutable && !self.mutable_container_classes.include?(type)
        add_weight(object)
        add_value(object) if self.added_value_container_classes.include?(type)
        set_property(type, get_property(type) << object)
        object
    end

    def _remove_object(object, type)
        raise(ArgumentError, "Invalid container class #{type}.") unless self.container_classes.include?(type)
        raise(ArgumentError, "Cannot modify #{type} composition of #{monicker}!") unless self.mutable_container_classes.include?(type)
        remove_weight(object)
        remove_value(object) if self.added_value_container_classes.include?(type)
        get_property(type).delete(object)
    end

    def add_weight(object)
        set_property(:weight, (get_property(:weight) || 0) + object.weight)
    end

    def remove_weight(object)
        set_property(:weight, get_property(:weight) - object.weight)
    end

    def add_value(object)
        set_property(:value, (get_property(:value) || 0) + object.value)
    end

    def remove_value(object)
        set_property(:value, get_property(:value) - object.value)
    end
end
