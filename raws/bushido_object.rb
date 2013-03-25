require './util/log'
require './util/exceptions'
require './game/object_extensions'

class BushidoObject
    class << self
        def pack(object)
            raw_data = {}

            raw_data[:uid]  = object.uid
            raw_data[:type] = object.get_type
            raw_data[:properties] = object.properties

            raw_data[:extensions] = {}
            object.extensions.each do |extension|
                raw_data[:extensions][extension] =
                    extension.respond_to?(:pack) ? extension.pack(object) : nil
            end

            raw_data
        end

        def unpack(core, raw_data)
            raise(ArgumentError, "Malformed packed object data") unless Hash === raw_data

            raise(MissingProperty, "Object type missing from packed data") unless raw_data[:type]
            object = self.new(core, raw_data[:type], raw_data[:uid])

            raise(MissingProperty, "Object properties missing from packed data") unless raw_data[:properties]
            object.set_properties(raw_data[:properties])

            raise(MissingProperty, "Object extensions missing from packed data") unless raw_data[:extensions]
            raw_data[:extensions].each_pair do |extension, data|
                object.add_extension(extension)
                if data && extension.respond_to?(:unpack)
                    extension.unpack(core, object, data)
                elsif extension.respond_to?(:unpack)
                    raise(MissingProperty, "Data missing for extension #{extension}")
                elsif data
                    Log.warning("Extension data present with no method for unpacking it")
                end
            end

            object
        end

        def create(core, type, uid, params={})
            # Create an empty object
            object = self.new(core, type, uid)

            type_info = core.db.raw_info_for(type)

            # Check required parameters
            type_info[:needs].each do |k|
                raise(ArgumentError, "Required argument #{k.inspect} missing during creation of #{type}.") unless params[k]
            end

            # Set up default property values
            type_info[:class_values].each do |k,v|
                unless type_info[:has].has_key?(k) && type_info[:has][k][:class_only]
                    object.properties[k] = Marshal.load(Marshal.dump(v))
                end
            end

            # Add extensions
            type_info[:uses].each do |mod|
                object.add_extension(mod)
            end

            # Perform first-time extension creation
            type_info[:uses].each do |mod|
                next unless mod.respond_to?(:at_creation)
                result = mod.at_creation(object, params)
                object.properties.merge!(result) if Hash === result
            end

            # Initialize property values
            type_info[:has].keys.each do |property|
                next if type_info[:has][property][:class_only]
                if type_info[:has][property][:multiple]
                    if object.properties[property].nil? ||
                      (object.properties[property].empty? && !type_info[:has][property][:optional])
                        raise(StandardError, "Property #{property.inspect} has no values for #{type}.")
                    end
                elsif object.properties[property].nil?
                    if type_info[:has][property][:optional]
                        object.properties[property] = nil
                    else
                        raise(StandardError, "Property #{property.inspect} has no value for #{type}.")
                    end
                end
            end

            return object
        end
    end

    attr_accessor :properties
    attr_reader   :extensions, :uid

    def get_type; @type; end

    def destroy(destroyer, vaporize=false)
        stop_listening

        @extensions.each do |mod|
            mod.at_destruction(self, destroyer, vaporize) if mod.respond_to?(:at_destruction)
        end
    end

    def transform(type, params)
        Transforms.transform(type, @core, self, params)
    end

    def start_listening_for(message_type)
        if @listens_for.keys.include?(message_type)
            @listens_for[message_type] += 1
        else
            @listens_for[message_type] = 1
            Message.register_listener(@core, message_type, self)
        end
    end

    def listens?
        !@listens_for.keys.empty?
    end

    def stop_listening_for(message_type)
        return unless @listens_for.keys.include?(message_type)

        if (@listens_for[message_type] -= 1) <= 0
            Message.unregister_listener(@core, message_type, self)
            @listens_for.delete(message_type)
        end
    end

    def stop_listening
        @listens_for.keys.each do |type|
            Message.unregister_listener(@core, type, self)
        end
        @listens_for.clear
    end

    def set_called(called)
        Log.debug("#{monicker} is now called #{called}")
        @called = called
    end

    def monicker
        @called || ((uses?(Karmic) && name) ? name : @type.text)
    end

    def is_type?(type)
        @core.db.is_type?(@type, type)
    end

    def matches(args = {})
        (args[:uses] ? self.uses?(args[:uses])    : true) &&
        (args[:type] ? self.is_type?(args[:type]) : true) &&
        (args[:name] ? self.monicker.match(/#{args[:name]}/i) : true)
    end

    def type_ancestry
        @core.db.ancestry_of(@type)
    end

    # This is a hack for Ruby 1.9 / 2.0
    # rb_ary_flatten tries to call to_ary on everything, and method_missing throws an exception
    # This method allows to_ary to be called with benign result to bypass that issue
    def to_ary; nil; end

    def process_message(message)
        Log.error("#{monicker} has no core!") unless @core
        @extensions.each do |mod|
            mod.at_message(self, message) if mod.respond_to?(:at_message)
        end
    end

    def class_info
        @core.db.info_for(@type)
    end

    def inspect
        "#<#{@type} #{@properties.inspect}>"
    end

    def to_formatted_string(prefix, nest_prefix=true)
        [@type, [@properties]].to_formatted_string(prefix, nest_prefix)
    end

    def add_extension(extension)
        @extensions << extension
        extend extension
        if extension.respond_to?(:listens_for)
            extension.listens_for.each do |message_type|
                start_listening_for(message_type)
            end
        end
    end
    def remove_extension(extension)
        return unless @extensions.include?(extension)
        @extensions.delete(extension)
        if extension.respond_to?(:listens_for)
            extension.listens_for.each do |message_type|
                stop_listening_for(message_type)
            end
        end
    end
    def uses?(extension); @extensions.include?(extension); end

    def set_properties(value)
        @properties = value
    end

    def initialize(core, type, uid)
        @core = core
        @type = type
        @uid  = uid

        @properties  = {}
        @extensions  = []
        @listens_for = {}
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

    def process_message(*args)
        check_destroyed
        super(*args)
    end

    def filter_objects(location, filters)
        raise(MissingObjectExtensionError, "The perception extension is required to filter objects") unless uses?(Perception)
    end
end
