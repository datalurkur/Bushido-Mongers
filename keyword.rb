require 'action'

class Keyword
    class << self
        def define(keyword, associations={}, &block)
            hash[keyword] = assocations.merge(:action => block)
        end

        def hash; @hash ||= {}; end
    end
end

Keyword.define(:food, {:target_of => :eat}) { |args|
    Log.debug("#{args[:agent]} eats #{args[:target]}")
}

Keyword.define(:thrown_weapon, {:utensil_of => :attack}) { |args|
    Log.debug("#{args[:agent]} throws #{args[:utensil]} at #{args[:target]}")
}
