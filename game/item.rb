class Item
    class << self
        def types
            @types ||= {}
        end

        def quality
            {
                :legendary   => 16,
                :masterwork  => 8,
                :superior    => 4,
                :fine        => 2,
                :decent      => 1,
                :substandard => 0.5,
                :dubious     => 0.25,
                :shoddy      => 0.125,
            }
        end

        def required_class_properties
            [
                :value,       # This is the basic item value used to determine the base value (which is based off of materials)
                :weight,      # This value is used to determine the weight of the thing based on the material it is produced from
                :size,        # This is the standard size of the item, though actual size depends on keywords and modifiers
                :made_from,   # An array of materials needed to construct the item, with each element in the array being an array of interchangeable components
                              # Example: Cupboard { :made_from => [[:wood,:stone],[:hinge]] } (A cupboard can be made from wood and a hinge or stone and a hinge)
                # :made_at,   # Not a required property, but required if the item needs a special workshop to make
                # :made_with, # Not a required property, but required if the item needs special tools to make
            ]
        end

        def required_instance_properties
            required_class_properties.concat([
                :value,     # The value of an item with the cost of its materials included
                :weight,    # The weight of the item
                :size,      # The final size of the item
                :quality,   # The quality of the workmanship
                :materials, # The materials of which the item is comprised
            ])
        end

        def check_required_properties(properties, requirements)
            requirements.each do |key|
                raise "Missing property #{key}" unless properties.has_key?(key)
            end
        end

        def describe(base_type, properties={})
            check_required_properties(properties, required_class_properties)
            types[base_type] = properties
        end
    end

    def initialize(name, base_type, properties={})
        @name       = name
        @base_type  = base_type

        derived_properties = derive_item_details(@base_type, properties)
        self.class.check_required_properties(derived_properties, required_instance_properties)
        @properties = properties
    end

    def derive_item_details(base_type, properties)
        derived_properties = {}

        # TODO - Determine derived properties using item materials, keywords, etc

        derived_properties
    end

    # For a lot of item properties (like weight and size) we'll fill in the details at instantiation time
    # For value, however, this can depend on a lot of other things (if a weapon has killed a lot of things, it might become legendary and be worth more, for example)
    def value
        # TODO - Add computations that factor in all the stuff that makes an item valuable
    end
end

class Equipment < Item
    class << self
        def required_class_properties
            super().concat([
                :slot,
            ])
        end
    end

    def initialize(name, base_type, properties={})
        super(name, base_type, properties)
    end
end

# DEBUG
Equipment.describe(:helmet, {
    :value     => 10,# TODO - Decide on a gold standard, so to speak (Example: for all items, the price assumes the item is made of iron and normal quality)
    :weight    => 2, # TODO - Make this value more descriptive - Does this mean the item is twice the weight of the materials?  Does this even need to be a property?
    :size      => :normal, # TODO - Actually hammer out what sizes are and what they mean (are they relative to the item type, relative to a person?) (Can persons be different sizes?)
    :made_from => [[:metal, :wood]],
    :made_at   => [:forge], # TODO - This raises an interesting problem, and one we solved with MH; do we want to get this detailed?  If so, we need to associate materials with construction techniques
}
