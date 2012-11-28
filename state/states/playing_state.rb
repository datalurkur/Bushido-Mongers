require 'state/state'

class PlayingState < State
    def initialize(client)
        super(client)

        define_exchange(:inspect_room, :server_query) do |result|
            @client.send_to_client(Message.new(:properties, {:field => :room_info, :properties => result}))
            begin_exchange(:playing_menu_choice)
        end

        define_exchange_chain([
            [:room_info_for_move, :server_query,     {:query_method => :inspect_room}],
            [:move_direction,     :choose_from_list, {:choices_from => [:room_info_for_move, :exits]}],
        ]) do |choice|
            @client.send_to_server(Message.new(:move, {:direction => choice}))
        end

        define_exchange(:playing_menu_choice, :choose_from_list, {:choices => playing_menu_choices}) do |choice|
            case choice
            when :inspect
                begin_exchange(:inspect_room)
            when :move
                begin_exchange(:room_info_for_move)
            #when :act
            end
        end

        begin_exchange(:playing_menu_choice)
    end

    def playing_menu_choices; [:inspect, :move, :act]; end

    def from_server(message)
        case message.type
        when :move_fail, :move_success
            pass_to_client(message)
            begin_exchange(:playing_menu_choice)
            return
        end
        super(message)
    end
end
