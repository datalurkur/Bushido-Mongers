module Profession
    class << self
        def at_creation(instance, params)
            instance.set_profession(params)
        end
    end

    def set_profession(params)
        types = @core.db.types_of(:profession)
        @properties[:job] = types.rand
    end

    def job
        @properties[:job]
    end
end
