require 'ninja'
require 'npc'

class Action
    class << self
        def define(action, roles={})
            hash[action] = roles
        end

        def add_roles(action, keyword, role)
            case role
            when :target_of;  hash[action][:target]  << keyword
            when :utensil_of; hash[action][:utensil] << keyword
            else
                raise "Unimplemented"
            end
        end

        def hash; @hash ||= {}; end
    end
end

Action.define(:eat)

Action.define(:attack, {
    :target => [Ninja, NPC]
}
