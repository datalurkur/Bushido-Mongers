require 'state/state'

class CreateCharacterState < State
    def initialize(client, method)
        super(client, method)
    end
end
