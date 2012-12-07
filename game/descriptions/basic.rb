require 'game/tables'

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
