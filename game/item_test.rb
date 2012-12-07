require 'game/dsl'
require 'game/tables'

Log.setup("Main Thread", "item_test")

ObjectDSL.describe(:item, {:abstract => true}) do
    has_properties :weight, :value
end

ObjectDSL.describe(:constructable, {:abstract => true}) do
    is_an Item
    has_properties :techniques, :quality

    requires_params :materials, :quality
    on_creation do |params|
        {
            :weight => params[:materials].inject(0) { |w,m| w + m.weight },
            :value  =>
                Quality.value(params[:quality]) *
                params[:materials].inject(0) { |v,m| v + m.value },
        }
    end
end

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

puts "Headgear list: #{Headgear.types}"
puts "Metal list: #{Metal.types}"
puts "Items list:"
Item.types.each do |type|
    puts type
    puts type.properties.inspect
    puts type.requires_params.inspect
end

iron = Iron.new
helmet = Helmet.new(:materials => [iron], :quality => :fine)
