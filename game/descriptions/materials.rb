ObjectDSL.describe(:material, {:abstract => true}) do
    is_an Item
end

ObjectDSL.describe(:metal, {:abstract => true}) do
    is_a Material
    has_property :melting_point
end

ObjectDSL.describe(:iron) do
    is_a Metal
    set :melting_point, 1538
    set :weight, 5
    set :value, 10
end
