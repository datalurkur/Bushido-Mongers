class Action
    class << self
        def describe(name,description,&block)
            @actions ||= {}
            @actions[name] = {
                :description => description,
                :block       => block
            }
        end

        def perform(name,arg_hash)
            unless @actions.has_key?(name)
                raise "Action #{name} not found"
            end

            @actions[name][:block].call(arg_hash)
        end
    end
end
