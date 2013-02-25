require './util/log'
require './util/exceptions'
require './game/object_extensions'

class BushidoObject
    attr_reader :type, :properties

    def initialize(core, type, params={})
        Log.debug("Creating #{type}", 6) unless core.db.types_of(:body_part).include?(type)
        @core = core
        @type = type

        @properties  = {}
        @extensions  = []
        @listens_for = []

        type_info = @core.db.raw_info_for(@type)

        type_info[:needs].each do |k|
            raise(ArgumentError, "Required argument #{k.inspect} missing during creation of #{@type}.") unless params[k]
        end

        type_info[:class_values].each do |k,v|
            unless type_info[:has].has_key?(k) && type_info[:has][k][:class_only]
                @properties[k] = Marshal.load(Marshal.dump(v))
            end
        end

        type_info[:uses].each do |mod|
            @extensions << mod
            extend mod
        end

        @extensions.each do |mod|
            next unless mod.respond_to?(:at_creation)
            result = mod.at_creation(self, params)
            @properties.merge!(result) if Hash === result
        end

        type_info[:has].keys.each do |property|
            next if type_info[:has][property][:class_only]
            if type_info[:has][property][:multiple]
                if @properties[property].nil? || (@properties[property].empty? && !type_info[:has][property][:optional])
                    raise(StandardError, "Property #{property.inspect} has no values for #{@type}.")
                end
            elsif @properties[property].nil?
                if type_info[:has][property][:optional]
                    @properties[property] = nil
                else
                    raise(StandardError, "Property #{property.inspect} has no value for #{@type}.")
                end
            end
        end
    end

    def destroy(destroyer, vaporize=false)
        stop_listening

        @extensions.each do |mod|
            mod.at_destruction(self, destroyer, vaporize) if mod.respond_to?(:at_destruction)
        end
    end

    def start_listening_for(message_type)
        return if @listens_for.include?(message_type)
        @listens_for << message_type
        Message.register_listener(@core, message_type, self)
    end

    def listens?
        !@listens_for.empty?
    end

    def stop_listening_for(message_type)
        return unless @listens_for.include?(message_type)
        Message.unregister_listener(@core, message_type, self)
        @listens_for.delete(message_type)
    end

    def stop_listening
        @listens_for.each do |type|
            Message.unregister_listener(@core, type, self)
        end
        @listens_for.clear
    end

    def monicker
        (get_property(:name) || @type).to_s
    end

    def is_type?(type)
        @core.db.is_type?(@type, type)
    end

    def uses?(mod)
        @core.db.raw_info_for(@type)[:uses].include?(mod)
    end

    def matches(args = {})
        (args[:type] ? self.is_type?(args[:type]) : true) &&
        (args[:name] ? self.monicker.match(/#{args[:name]}/i) : true)
    end

    def type_ancestry
        @core.db.ancestry_of(@type)
    end

    def method_missing(method_name, *args, &block)
        if @properties.has_key?(method_name)
            @properties[method_name]
        else
            raise(ArgumentError, "Property #{method_name.inspect} not found for #{@type}.")
        end
    end

    # This is a hack for Ruby 1.9 / 2.0
    # rb_ary_flatten tries to call to_ary on everything, and method_missing throws an exception
    # This method allows to_ary to be called with benign result to bypass that issue
    def to_ary; nil; end

    def get_property(key)
        @properties[key]
    end

    def set_property(key, value)
        # TODO - Properly check type of value based on raw type information
=begin
        if !@properties[key].nil? &&
                value.class != @properties[key].class &&
                !(Numeric === value.class && Numeric === @properties[key].class)
            Log.warning("Changing class of property #{key}: from #{@properties[key].class} to #{value.class}")
        end
=end
        @properties[key] = value
    end

    def has_property?(prop)
        @properties.has_key?(prop)
    end

    def process_message(message)
        Log.error("#{monicker} has no core!") unless @core
        @extensions.each do |mod|
            mod.at_message(self, message) if mod.respond_to?(:at_message)
        end
    end

    def class_info(key)
        @core.db.info_for(@type, key)
    end

    def class_properties
        @core.db.info_for(@type)
    end

    def inspect
        "#<#{@type} #{@properties.inspect}>"
    end

    def to_formatted_string(prefix, nest_prefix=true)
        [@type, [@properties]].to_formatted_string(prefix, nest_prefix)
    end
end

class SafeBushidoObject < BushidoObject
    attr_reader :destroyed

    def initialize(*args)
        super(*args)
        @properties[:destroyed] = false
    end

    def check_destroyed
        Log.warning(["Destroyed object #{@type} being used!", caller]) if @properties[:destroyed]
    end

    def destroy(*args)
        Log.info("Destroying #{@type} (#{object_id})", 8)
        check_destroyed
        super(*args)
        @properties[:destroyed] = true
    end

    def monicker
        check_destroyed
        super()
    end

    def method_missing(*args, &block)
        check_destroyed
        super(*args, &block)
    end

    def set_property(*args)
        check_destroyed
        super(*args)
    end

    def process_message(*args)
        check_destroyed
        super(*args)
    end

    def filter_objects(location, type, name)
        raise(MissingObjectExtensionError, "The perception extension is required to filter objects") unless uses?(Perception)
    end
end
