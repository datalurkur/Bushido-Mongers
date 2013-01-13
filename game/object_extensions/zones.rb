require './util/log'

module Zones
    class << self
        def at_creation(instance, params)
            keywords = instance.keywords + (params[:inherited_keywords] || [])
            instance.set_property(:keywords, keywords)
        end
    end
end
