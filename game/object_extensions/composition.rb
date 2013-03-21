require './util/log'
require './util/exceptions'

# TODO - check for relative size / max carry number / other restrictions

module Composition
    class << self
        def pack(instance)
            raw_data = {:containers => {}}
            instance.container_classes.each do |container_class|
                raw_data[:containers][container_class] = instance.container_contents(container_class).collect do |object|
                    BushidoObject.pack(object)
                end
            end
            raw_data
        end

        def unpack(core, instance, raw_data)
            raise(MissingProperty, "Composition data corrupted") unless raw_data[:containers]
            raw_data[:containers].each_pair do |container_class, container_contents|
                instantiated_contents = container_contents.collect do |object|
                    BushidoObject.unpack(core, object)
                end
                instance.set_container_contents(container_class, instantiated_contents)
            end
        end

        def at_creation(instance, params)
            instance.properties[:weight] = 0
            instance.initial_composure(params)
        end

        def at_destruction(instance, destroyer, vaporize)
            return if vaporize

            Log.debug("Destroying composition #{instance.monicker}", 7)
            instance.container_classes.each do |klass|
                if instance.preserved?(klass)
                    # Drop these components at the location where this object is
                    instance.container_contents(klass).each do |component|
                        Log.debug("Dropping #{component.monicker} at #{instance.absolute_position.name}", 6)
                        component.drop(instance.absolute_position)
                    end
                    # All components set to a new location. Clear the local references.
                    instance.set_container_contents(klass, [])
                else
                    Log.debug("#{instance.monicker} does not preserve #{klass} components", 8)
                end
            end
        end
    end

    def initial_composure(params)
        symmetric_parts.each do |symmetric_part|
            unless composed_of?(symmetric_part[:container_class])
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

        container_classes.each do |comp_type|
            raise(MissingProperty, "Container class #{comp_type} specified but not created.") unless @properties[comp_type]
            @properties[comp_type].each do |component|
                @core.create(component, params.merge(
                    :position      => self,
                    :position_type => comp_type,
                    :randomize     => true
                ))
            end
        end
    end

    # TODO - check for relative size / max carry number / other restrictions
    # respect_mutable=false is used by various at_creation methods to assemble objects sans-sanity checks
    def add_object(object, type=:internal, respect_mutable=true)
        Log.debug("Assembling #{monicker} - #{object.monicker} added to list of #{type} parts", 6)
        _add_object(object, type, respect_mutable)
    end

    def remove_object(object, klass = nil)
        Log.debug("Removing #{object.monicker} from #{monicker}", 6)
        if klass
            if container_contents(klass).include?(object)
                return _remove_object(object, klass)
            end
        else
            self.container_classes.each do |klass|
                if container_contents(klass).include?(object)
                    return _remove_object(object, klass)
                end
            end
        end
        raise(NoMatchError, "No matching object #{object.monicker} found.")
    end

    def full?(type=:internal)
        case type
        when :grasped
            container_contents(type).size > 0
        when :worn
            container_contents(type).size > 1
        else
            false
        end
    end

    def container?
        self.composed_of?(:internal) && self.mutable?(:internal)
    end

    # the openable raw type doesn't have its own objext, but the
    # method makes sense in composition too.
    def open?
        # If it's a container, assume open unless directly contradicted.
        self.container? && (self.is_type?(:openable) ? @properties[:open] : true)
    end

    def containers(type, recursive=true)
        select_objects(type, recursive) { |obj| cont.uses?(Composition) && cont.container? }
    end

    def select_objects(type, recursive=false, depth=5, &block)
        types = Array(type)
        list = []
        types.each do |type|
            next unless @properties[type]
            container_contents(type).each do |obj|
                next if block_given? && !block.call(obj)
                list << obj
                if recursive && obj.is_type?(:composition) && depth > 0
                    list += obj.select_objects(type, recursive, depth - 1, &block)
                end
            end
        end
        list
    end

    def container_contents(type=:internal)
        @container_contents       ||= {}
        raise(ArgumentError, "Invalid container class #{type}.") unless composed_of?(type)
        @container_contents[type] ||= []
    end

    def set_container_contents(type, value)
        @container_contents               ||= {}
        raise(ArgumentError, "Invalid container class #{type}.") unless composed_of?(type)
        @container_contents[type] = value
    end

    def container_classes;     @properties[:container_classes];             end
    def mutable_classes;       @properties[:mutable_container_classes];     end
    def valued_classes;        @properties[:added_value_container_classes]; end
    def symmetric_parts;       @properties[:symmetric];                     end

    def composed_of?(klass);   @properties[:container_classes].include?(klass);             end
    def mutable?(klass);       @properties[:mutable_container_classes].include?(klass);     end
    def valued?(klass);        @properties[:added_value_container_classes].include?(klass); end
    def preserved?(klass);     @properties[:preserved_container_classes].include?(klass);   end

    private
    def _add_object(object, type, respect_mutable)
        raise(ArgumentError, "Invalid container class #{type}.") unless composed_of?(type)
        raise(ArgumentError, "Cannot modify #{type} composition of #{monicker}!") if respect_mutable && !mutable?(type)
        add_weight(object)
        add_value(object) if valued?(type)
        container_contents(type) << object
        object
    end

    def _remove_object(object, type)
        raise(ArgumentError, "Invalid container class #{type}.") unless composed_of?(type)
        raise(ArgumentError, "#{type} contents of #{monicker} are immutable.") unless mutable?(type)
        remove_weight(object)
        remove_value(object) if valued?(type)
        container_contents(type).delete(object)
    end

    def add_weight(object);    @properties[:weight] += object.properties[:weight]; end
    def remove_weight(object); @properties[:weight] -= object.properties[:weight]; end
    def add_value(object);     @properties[:value]  += object.properties[:value];  end
    def remove_value(object);  @properties[:value]  -= object.properties[:value];  end
end
