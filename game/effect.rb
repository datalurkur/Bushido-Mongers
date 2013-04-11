class Effect
    def initialize(transforms)
        @transforms = transforms
    end

    def apply(objects)
        objects.each do |object|
            @transforms.each do |transform, params|
                Transforms.transform(transform, object, params)
            end
        end
    end
end
