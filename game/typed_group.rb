class TypedGroup
    class << self
        def types
            @types ||= {}
        end

        def required_class_properties
            []
        end

        def check_required_properties(properties, requirements)
            requirements.each do |key|
                raise "Missing property #{key}" unless properties.has_key?(key)
            end
        end

        def describe(type, properties)
            check_required_properties(properties, required_class_properties)
            types[base_type] = properties
        end
    end
end

class InstantiableTypedGroup < TypedGroup
    class << self
        def required_instance_properties
            []
        end

        def derive_item_details(base_type, properties)
            properties
        end
    end

    def initialize(name, base_type, properties)
        @name      = name
        @base_type = base_type

        derived_properties = self.class.derive_item_details(@base_type, properties)
        self.class.check_required_properties(derived_properties, required_instance_properties)
        @properties = derived_properties
    end
end
