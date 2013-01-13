require './util/log'
require './game/object_extensions'

class BushidoObject
    attr_reader :type, :properties

    def initialize(core, type, params={})
        Log.debug("Creating #{type}", 6) unless core.db.types_of(:body_part).include?(type)
        @core = core
        @type = type

        @properties = {}
        @extensions = []

        type_info = @core.db.raw_info_for(@type)

        type_info[:needs].each do |k|
            raise "Required argument #{k.inspect} missing during creation of #{@type}" unless params[k]
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
            mod.at_creation(self, params) if mod.respond_to?(:at_creation)
        end

        type_info[:at_creation].each do |creation_proc|
            result = eval(creation_proc, nil, __FILE__, __LINE__)
            if Hash === result
                @properties.merge!(result)
            end
        end

        type_info[:has].keys.each do |property|
            next if type_info[:has][property][:class_only]
            if type_info[:has][property][:multiple]
                if @properties[property].empty? && !type_info[:has][property][:optional]
                    raise "Property #{property.inspect} has no values for #{@type}"
                end
            else
                unless @properties[property]
                    if type_info[:has][property][:optional]
                        @properties[property] = nil
                    else
                        raise "Property #{property.inspect} has no value for #{@type}"
                    end
                end
            end
        end

        self
    end

    def destroy(destroyer)
        @core.db.raw_info_for(@type)[:at_destruction].each do |destruction_proc|
            eval(destruction_proc, nil, __FILE__, __LINE__)
        end

        @extensions.each do |mod|
            mod.at_destruction(self) if mod.respond_to?(:at_destruction)
        end

        if @position
            Message.dispatch(@core, :object_destroyed, :agent => destroyer, :position => @position, :target => self)
        else
            Log.warning("#{monicker} is being destroyed but has no position")
        end
    end

    def monicker
        (@properties[:name] || @type).to_s
    end

    def is_type?(type)
        @core.db.is_type?(@type, type)
    end

    def type_ancestry
        types   = []
        current = [@type]
        until current.empty?
            types.concat(current)
            current = current.collect { |t| @core.db.raw_info_for(t)[:is_type] }.flatten.uniq
            current.reject! { |t| t == :root }
        end
        types
    end

    def method_missing(method_name, *args, &block)
        if @properties.has_key?(method_name)
            @properties[method_name]
        else
            raise "Property #{method_name.inspect} not found for #{@type}"
        end
    end

    def set_property(key, value)
        @properties[key] = value
    end

    def has_property?(prop)
        @properties.has_key?(prop)
    end

    def process_message(message)
        @extensions.each do |mod|
            break if mod.respond_to?(:at_message) && mod.at_message(self, message)
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
        @destroyed = false
        super(*args)
    end

    def check_destroyed
        Log.warning(["Destroyed object being used!", caller]) if @destroyed
    end

    def destroy(*args)
        check_destroyed
        super(*args)
        @destroyed = true
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
end
