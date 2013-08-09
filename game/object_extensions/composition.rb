require './util/log'
require './util/exceptions'

module Composition
    class << self
        def pack(instance)
            raw_data = {
                :containers => {},
                :size       => instance.size
            }
            instance.container_classes.each do |container_class|
                raw_data[:containers][container_class] = instance.container_contents(container_class).collect do |object|
                    BushidoObject.pack(object)
                end
            end
            raw_data
        end

        def unpack(core, instance, raw_data)
            [:size, :containers].each do |key|
                raise(MissingProperty, "Composition data corrupted") unless raw_data[key]
            end
            raw_data[:containers].each_pair do |container_class, container_contents|
                instantiated_contents = container_contents.collect do |object|
                    BushidoObject.unpack(core, object)
                end
                instance.set_container_contents(container_class, instantiated_contents)
            end
            instance.size = raw_data[:size]
        end

        def at_creation(instance, params)
            raise(ObjectExtensionCollision, "Composition and Atomic are not compatible object extensions") if instance.uses?(Atomic)

            instance.size = if params[:size]
                params[:size]
            elsif params[:relative_size]
                Size.adjust(instance.class_info[:typical_size], params[:relative_size])
            else
                instance.class_info[:typical_size]
            end

            instance.initial_composure(params)

            called = params[:called] || instance.properties[:called]
            instance.set_called(called) if called
        end

        def at_destruction(instance, destroyer, vaporize)
            return if vaporize

            instance.container_classes.each do |klass|
                # Drop these parts at the location where this object is
                instance.container_contents(klass).dup.each do |part|
                    Log.debug("Dropping (#{klass}) #{part.monicker} at #{instance.absolute_position.monicker}", 6)
                    part.set_position(instance.absolute_position, :internal)
                end
            end
        end

        def typical_parts_of(core, type, morphism)
            type_info     = core.db.info_for(type)
            typical_parts = []
            type_info[:container_classes].each do |klass|
                new_parts = type_info[klass].collect do |part|
                    {
                        :type  => part,
                        :count => 1,
                        :klass => klass
                    }
                end
                typical_parts.concat(new_parts)
            end
            complex_parts = type_info[:symmetric]
            complex_parts += type_info[:morphic].select { |p| p[:morphism_classes].include?(morphism) } if morphism
            complex_parts.each do |part|
                typical_parts << {
                    :type  => part[:object_type],
                    :count => part[:count] || 1,
                    :klass => part[:container_class]
                }
            end
            typical_parts
        end
    end

    attr_accessor :size

    def weight
        container_classes.inject(0) do |total_sum,klass|
            total_sum + container_contents(klass).inject(0) do |container_sum,object|
                container_sum + object.weight
            end
        end
    end

    def value
        container_classes.select { |i| valued?(i) }.inject(0) do |total_sum,klass|
            total_sum + container_contents(klass).inject(0) do |container_sum,object|
                container_sum + object.value
            end
        end
    end

    def integrity
        raise(UnexpectedBehaviorError, "#{monicker} has no incidentals!") if container_contents(:incidental).empty?
        container_contents(:incidental).inject(0) do |sum,object|
            sum + object.integrity
        end
    end

    def damage(amount, attacker)
        if container_contents(:incidental).empty?
            Log.warning(self)
            raise(UnexpectedBehaviorError, "#{monicker} has no incidentals!")
        end
        part = container_contents(:incidental).rand
        Log.debug("Composition taking damage (#{amount}), dealt to #{part.monicker}")
        part.damage(amount, attacker)
    end

    def apply_transform(transform, params)
        # TODO - Figure out how this should work in light of layering
        (container_classes - [:internal]).each do |klass|
            container_contents(klass).each do |part|
                Transforms.transform(transform, @core, part, params)
            end
        end
    end

    def initial_composure(params)
        Composition.typical_parts_of(@core, get_type, params[:morphism]).each do |part|
            unless composed_of?(part[:klass])
                Log.error("No container class #{part[:klass].inspect} found for #{monicker}")
                next
            end
            part[:count].times do |i|
                # FIXME - Actually use the symmetry class to assign names here
                @core.create(part[:type], params.merge(
                    :position      => self,
                    :position_type => part[:klass],
                    :randomize     => true
                ))
            end
        end
    end

    def contents; container_contents(:internal); end

    # TODO - check for relative size / max carry number / other restrictions
    def add_object(object, type)
        Log.debug("Assembling #{monicker} - #{object.monicker} added to list of #{type} parts", 6)
        raise(ArgumentError, "Invalid container class #{type}.") unless composed_of?(type)
        container_contents(type) << object
    end
    def remove_object(object, type)
        Log.debug("Removing #{object.monicker} from #{monicker}", 6)
        raise(ArgumentError, "Invalid container class #{type}.") unless composed_of?(type)
        unless container_contents(type).include?(object)
            Log.error("No object #{object.monicker} found in #{monicker}'s #{type}s")
            return
        end
        container_contents(type).delete(object)
    end

    def component_destroyed(object, type, destroyer)
        remove_object(object, type)

        Log.debug("#{type} of #{monicker} destroyed")
        if type == :incidental
            Log.debug("#{monicker} falls to pieces")
            @core.flag_for_destruction(self, destroyer)
        end
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

    def open?
        # If it's a container, assume open unless directly contradicted.
        self.container? && (self.is_type?(:container) ? @properties[:open] : true)
    end

    def containers(type, recursive=true)
        select_objects(type, recursive) { |obj| obj.uses?(Composition) && obj.container? }
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

    def container_contents(type)
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

    def composed_of?(klass);   @properties[:container_classes].include?(klass);             end
    def mutable?(klass);       @properties[:mutable_container_classes].include?(klass);     end
    def valued?(klass);        @properties[:added_value_container_classes].include?(klass); end

    # DEBUG
    def composition_layout
        layout = {}
        container_classes.each do |klass|
            layout[klass] = {}
            container_contents(klass).each do |part|
                key = "#{part.monicker} (#{part.uid})"
                layout[klass][key] = part.uses?(Composition) ? part.composition_layout : nil
            end
        end
        layout
    end
end
