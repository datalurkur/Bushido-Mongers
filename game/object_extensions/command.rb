module Command
    class << self
        def at_creation(instance, params)
            unless instance.respond_to?(:on_command)
                raise "Command callback not defined for #{instance.class}"
            end
        end
    end
end
