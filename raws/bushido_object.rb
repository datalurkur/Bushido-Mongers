class BushidoObject
    #attr_reader :core, :type
    def initialize(core, type, params={})
        Log.debug("Creating #{type}", 6)
        Log.debug(["Creation params", params], 8)
        @core = core
        @type = type

        @properties = {}
        @extensions = []

        type_info = @core.db.raw_info_for(type)
        Log.debug(["Type info", type_info], 8)

        type_info[:needs].each do |k|
            raise "Required argument #{k.inspect} missing during creation of #{type}" unless params[k]
        end

        type_info[:class_values].each do |k,v|
            unless type_info[:has].has_key?(k) && type_info[:has][k][:class_only]
                (@properties[k] = v) 
            end
        end

        type_info[:at_creation].each do |creation_proc|
            result = eval(creation_proc, nil, __FILE__, __LINE__)
            if Hash === result
                @properties.merge!(result)
            end
        end

        Log.debug("#{type} invoking #{type_info[:uses].size} extensions", 8)
        type_info[:uses].each do |mod|
            @extensions << mod
            extend mod
        end

        @extensions.each do |mod|
            if mod.respond_to?(:at_creation)
                mod.at_creation(self, params)
            end
        end

        type_info[:has].keys.each do |property|
            next if type_info[:has][property][:class_only]
            if type_info[:has][property][:multiple]
                if @properties[property].empty? && !type_info[:has][property][:optional]
                    raise "Property #{property} has no values"
                end
            else
                unless @properties[property]
                    if type_info[:has][property][:optional]
                        @properties[property] = nil
                    else
                        raise "Property #{property} has no value"
                    end
                end
            end
        end

        self
    end

    def is_a?(type)
        (return false) if (@type == :root)
        current = [@type]
        until current.empty?
            if current.include?(type)
                return true
            else
                current = current.collect { |t| @core.db.raw_info_for(t)[:is_a] }.flatten.uniq
            end
            current.reject! { |t| t == :root }
        end
        return false
    end

    def method_missing(method_name, *args, &block)
        if @properties.has_key?(method_name)
            @properties[method_name]
        else
            raise "Property #{method_name.inspect} not found for #{@type}"
        end
    end

    def process_message(message)
        @extensions.each do |mod|
            break if mod.respond_to?(:at_message) && mod.at_message(self, message)
        end
    end

    def class_info(key)
        @core.db.info_for(@type, key)
    end
end
