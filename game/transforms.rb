module Transforms
    class << self
        public
        def transform(object, transformation)
            raise(ArgumentError, "Unknown transformation type #{transformation.inspect}") unless respond_to?(transformation)
            method(transformation).call(object)
        end

        private
        def death(object)
            Log.error("Not implemented")

            object
        end
    end
end
