require 'state/state'

class PlayingState < State
    def initialize(client)
        super(client)

        define_exchange(:menu_choice, :choose_from_list, {:choices => menu_choices}) do |choice|
            case choice
            when :inspect
            when :move
            when :act
            end
        end
    end

    def menu_choices; [:inspect, :move, :act]; end

    def from_server(message)
        #case message.type
        #end

        super(message)
    end
end
