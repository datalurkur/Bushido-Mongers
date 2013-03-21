module Transforms
    class << self
        def transform(object, transformation)
            raise(ArgumentError, "Unknown transformation type #{transformation.inspect}") unless respond_to?(transformation)
            method(transformation).call(object)
        end

        def death(object)
            Log.error("Not implemented")

            object
        end
    end
end
