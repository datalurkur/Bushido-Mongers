require 'util/basic'
require 'util/log'

module AbstractType
    def types
        Log.debug(["Collecting subtypes for #{self}", properties, required_params, on_create])
        type_register.collect do |subtype|
            if AbstractType === subtype
                subtype.types
            else
                subtype
            end
        end.flatten
    end

    def included(klass)
        Log.debug("#{klass} registered as a child of #{self}")
        type_register << klass
        klass.merge_parent(self)
    end

    private
    def type_register; @types ||= []; end
end

module ObjectType
    def self.included(klass)
        class << klass
            def is_a(mod)
                raise "Can't inherit from #{mod} - not an abstract type" unless Module === mod
                include mod
            end
            alias :is_an :is_a

            def properties; @properties ||= {}; end
            def has_property(key, value=nil)
                properties[key] = value
            end
            def has_properties(*keys)
                keys.each { |key| has_property(key) }
            end
            alias :set_property :has_property
            alias :set :has_property

            def required_params; @params ||= []; end
            def requires_params(*params)
                params.each { |param| requires_param(param) }
            end
            def requires_param(param)
                required_params << param
            end

            def on_create; @on_create ||= []; end
            def on_creation(&block)
                @on_create << block
            end

            def merge_parent(parent)
                Log.debug("Merging properties from #{parent} into #{self}")
                set_properties(parent.properties.merge(properties))
                set_required_params(required_params.concat(parent.required_params).uniq)
                set_on_create(parent.on_create + on_create)
            end

            def create_property_readers
                properties.keys.each do |prop|
                    define_method(prop) { @properties[prop] }
                end
            end

            private
            def set_on_create(value); @on_create = value; end
            def set_required_params(value); @required_params = value; end
            def set_properties(value); @properties = value; end
        end
    end

    def initialize(params={})
        @properties = self.class.properties.dup
        self.class.required_params.each do |required|
            raise "Required parameter #{required} not specified" unless params[required]
        end
        @properties.merge!(params)
        self.class.on_create.each do |proc|
            derived_properties = proc.call(params)
            @properties.merge!(derived_properties)
        end

        verify_properties
    end

    def verify_properties
        self.class.properties.keys.each do |prop|
            raise "Property #{prop} not defined for #{self.class}" unless @properties[prop]
        end
    end
end

module ObjectDSL
    class << self
        def describe(type, args={}, &block)
            Log.debug("Describing #{type}")
            type_class = args[:abstract] ? create_module(type) : create_class(type)
            type_class.class_exec { include ObjectType }
            type_class.class_exec { extend AbstractType } if args[:abstract]
            type_class.class_exec(&block) if block_given?
            type_class.create_property_readers
            puts type_class.properties.inspect
            puts type_class.required_params.inspect
        end

        def create_module(symbolic_name)
            create_generic(:module, symbolic_name)
        end

        def create_class(symbolic_name)
            create_generic(:class, symbolic_name)
        end

        def create_generic(type, symbolic_name)
            string_name = symbolic_name.to_caml
            Object.class_eval %{ #{type} #{string_name}; end }
            object_const = string_name.to_const
            object_const
        end
    end
end
