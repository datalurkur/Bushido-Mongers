module Corporeal
    class Body
        def initialize
            @parts = {}
        end

        def has_part?(part)
            @parts.has_key?(method_name)
        end

        def get_part(part)
            @parts[part]
        end

        def add_part(name, part)
            @parts[name] = part
        end

        def method_missing(method_name, *args, &block)
            if has_part?(method_name)
                get_part(method_name)
            else
                Log.debug("Part #{method_name} is not a part of body")
                nil
            end
        end
    end

    attr_reader :body

    def create_body(core, parts_list)
        @body = Body.new
        parts_list.each do |part|
            @body.add_part(part, core.db.create(core, part))
        end
    end
end
