class KBQuanta
    attr_reader :thing, :connector, :property, :args

    def initialize(args = {})
        @thing     = args[:thing]
        raise "Knowledge must be connected to something!" if @thing.nil?
        @connector = args[:connector] || :is
        @property  = args[:property]  || nil
        @args      = args
    end

    def self.args(thing, connector, property)
        { :thing => thing, :connector => connector, :property => property }
    end

    def hash
        # Note that this does not contain auxiliary args, which may vary.
        KBQuanta.args(@thing, @connector, @property).hash
    end

    def add_args(args)
        @args.merge!(args)
    end
end
