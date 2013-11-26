require './util/log'
require './util/exceptions'

module Composition
    class << self
        def pack(instance)
            {
                :containers => instance.pack_container_contents,
                :size       => instance.size
            }
        end

        def unpack(core, instance, raw_data)
            [:size, :containers].each do |key|
                raise(MissingProperty, "Composition data corrupted (#{key})") unless raw_data.has_key?(key)
            end
            instance.unpack_container_contents(raw_data[:containers])
            instance.size = raw_data[:size]
        end

        def at_creation(instance, params)
            raise(ObjectExtensionCollision, "Composition requires Position") if !instance.uses?(Position)
            raise(ObjectExtensionCollision, "Composition and Atomic are not compatible object extensions") if instance.uses?(Atomic)

            instance.size = if params[:size]
                params[:size]
            elsif params[:relative_size]
                Size.adjust(instance.class_info[:typical_size], params[:relative_size])
            else
                instance.class_info[:typical_size]
            end

            instance.initial_composure(params)

            instance.set_called(params[:called]) if params[:called]
        end

        def at_destruction(instance, destroyer, vaporize)
            return if vaporize

            instance.container_classes.each do |klass|
                # Drop these parts at the location where this object is
                instance.get_contents(klass).each do |part|
                    Log.debug("Dropping (#{klass}) #{part.monicker} at #{instance.absolute_position.monicker}", 6)
                    part.set_position(instance.absolute_position, :internal)
                end
            end
        end

        def typical_parts_of(core, type, morphism)
            type_info     = core.db.info_for(type)
            typical_parts = []
            type_info[:container_classes].each do |klass|
                type_info[klass].each do |part|
                    typical_parts << {
                        :type  => part,
                        :count => 1,
                        :klass => klass
                    }
                end
            end
            symmetric_parts = type_info[:symmetric]
            morphic_parts   = type_info[:morphic].select { |p| p[:morphism_classes].include?(morphism) }
            (symmetric_parts + morphic_parts).each do |part|
                typical_parts << {
                    :type       => part[:object_type],
                    :count      => part[:count] || 1,
                    :klass      => part[:container_class],
                    :symmetries => part[:symmetries]
                }
            end
            typical_parts
        end
    end

    def pack_container_contents;         @container_contents;        end
    def unpack_container_contents(hash); @container_contents = hash; end

    attr_accessor :size

    def weight
        container_classes.inject(0) do |total_sum,klass|
            total_sum + get_contents(klass).inject(0) do |container_sum,object|
                container_sum + object.weight
            end
        end
    end

    def value
        container_classes.select { |i| valued?(i) }.inject(0) do |total_sum,klass|
            total_sum + get_contents(klass).inject(0) do |container_sum,object|
                container_sum + object.value
            end
        end
    end

    def integrity
        raise(UnexpectedBehaviorError, "#{monicker} has no incidentals!") if container_contents(:incidental).empty?
        get_contents(:incidental).inject(0) do |sum,object|
            sum + object.integrity
        end
    end

    def damage(amount, attacker)
        if container_contents(:incidental).empty?
            Log.warning(self)
            raise(UnexpectedBehaviorError, "#{monicker} has no incidentals!")
        end
        part_id = container_contents(:incidental).rand
        part    = @core.lookup(part_id)
        Log.debug("Composition taking damage (#{amount}), dealt to #{part.monicker}")
        part.damage(amount, attacker)
    end

    def apply_transform(transform, params)
        # TODO - Figure out how this should work in light of layering
        (container_classes - [:internal]).each do |klass|
            get_contents(klass).each do |part|
                Transforms.transform(transform, @core, part, params)
            end
        end
    end

    def initial_composure(params)
        @morphism = params[:morphism]
        Composition.typical_parts_of(@core, get_type, @morphism).each do |part|
            unless composed_of?(part[:klass])
                Log.error("No container class #{part[:klass].inspect} found for #{monicker}")
                next
            end

            Log.debug("Creating #{part.inspect}", 7)

            if part[:symmetries]
                symmetries = []
                part[:symmetries].each do |symmetry|
                    Log.error("No symmetry class #{symmetry} found for #{monicker}") unless @core.db.types_of(:symmetry).include?(symmetry)
                    symmetries << @core.db.info_for(symmetry).merge(:count => 0)
                end
            end

            part[:count].times do |i|
                symmetry_positions = self.get_symmetry || []
                if symmetries
                    symmetries.each do |info|
                        symmetry_positions << info[:portions][info[:count]]
                        info[:count] += 1
                    end
                end

                @core.create(part[:type], params.merge(
                    :position           => self,
                    :position_type      => part[:klass],
                    :symmetry_positions => symmetry_positions,
                    :randomize          => true
                ))
            end
        end
    end

    def typical_parts
        Composition.typical_parts_of(@core, get_type, @morphism)
    end

    # TODO - check for relative size / max carry number / other restrictions
    def add_object(object, type)
        Log.debug("Assembling #{monicker} - #{object.monicker} added to list of #{type} parts", 6)
        raise(ArgumentError, "Invalid container class #{type}.") unless composed_of?(type)
        container_contents(type) << object.uid
    end
    def remove_object(object, type)
        Log.debug("Removing #{object.monicker} from #{monicker}", 6)
        raise(ArgumentError, "Invalid container class #{type}.") unless composed_of?(type)
        unless container_contents(type).include?(object.uid)
            Log.error(["No #{object.monicker} found in #{monicker}'s #{type}s", caller])
            return
        end
        container_contents(type).delete(object.uid)
    end

    def component_destroyed(object, type, destroyer)
        remove_object(object, type)

        Log.debug("#{type} of #{monicker} destroyed")
        if type == :incidental
            Log.debug("#{monicker} falls to pieces")
            @core.flag_for_destruction(self, destroyer)
        end
    end

    def full?(type = :internal)
        case type
        when :grasped
            container_contents(type).size > 0
        when :worn
            container_contents(type).size > 1
        when :internal, :external
            false
        else
            true
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
            get_contents(type).each do |obj|
                next if block_given? && !block.call(obj)
                list << obj
                if recursive && obj.is_type?(:composition) && depth > 0
                    list += obj.select_objects(type, recursive, depth - 1, &block)
                end
            end
        end
        list
    end

    def container_classes;     @properties[:container_classes];             end
    def mutable_classes;       @properties[:mutable_container_classes];     end
    def valued_classes;        @properties[:added_value_container_classes]; end

    def composed_of?(klass);   @properties[:container_classes].include?(klass);             end
    def mutable?(klass);       @properties[:mutable_container_classes].include?(klass);     end
    def valued?(klass);        @properties[:added_value_container_classes].include?(klass); end

    def get_contents(type)
        container_contents(type).collect { |obj_id| @core.lookup(obj_id) }
    end

    # DEBUG
    def composition_layout
        layout = {}
        container_classes.each do |klass|
            layout[klass] = {}
            get_contents(klass).each do |part|
                key  = "#{part.monicker} (#{part.uid})"
                layout[klass][key] = part.uses?(Composition) ? part.composition_layout : nil
            end
        end
        layout
    end

private
    def container_contents(type)
        @container_contents       ||= {}
        raise(ArgumentError, "Invalid container class #{type}.") unless composed_of?(type)
        @container_contents[type] ||= []
    end
end
