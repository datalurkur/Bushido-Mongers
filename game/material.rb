require 'game/typed_group'

class Material < TypedGroup
    class << self
        def required_class_properties
            [
                :weight,
                :value
            ]
        end
    end
end

Material.describe(:iron, {
    :weight => 5,
    :value  => 5,
})
