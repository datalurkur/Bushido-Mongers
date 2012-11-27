require 'state/state'

class PlayingState < State
    def initialize(client)
        super(client)

        define_exchange(:playing_menu_choice, :choose_from_list, {:choices => playing_menu_choices}) do |choice|
            case choice
            when :inspect
                @client.send_to_server(Message.new(:inspect_room))
            when :move
                # FIXME
                @client.send_to_server(Message.new(:inspect_room))
            when :act
                # FIXME
                @client.send_to_server(Message.new(:inspect_room))
            end
        end

        begin_exchange(:playing_menu_choice)
    end

    def playing_menu_choices; [:inspect, :move, :act]; end

    def from_server(message)
        case message.type
        when :room_info
            Log.debug(["Received room info from server", message.name, message.keywords, message.contents, message.exits])
            return
        end

        super(message)
    end
end
