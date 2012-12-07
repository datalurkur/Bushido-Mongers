ObjectDSL.describe(:equippable, {:abstract => true}) do
    is_a Constructable
    has_property :slot
end

ObjectDSL.describe(:headgear, {:abstract => true}) do
    is_an Equippable
    set :slot, :head
end

ObjectDSL.describe(:helmet) do
    is_a Headgear
end
