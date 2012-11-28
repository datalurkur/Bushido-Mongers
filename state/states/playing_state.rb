require 'state/state'

class PlayingState < State
    def initialize(client)
        super(client)

        @inspect_room_exchange = define_exchange(:server_query, {:query_method => :inspect_room}) do |result|
            @client.send_to_client(Message.new(:properties, {:field => :room_info, :properties => result}))
            begin_exchange(@playing_menu_exchange)
        end

        @move_exchange = define_exchange_chain([
            [:server_query,     {:query_method => :inspect_room}],
            [:choose_from_list, {:field => :direction, :choices_from => :exits}],
        ]) do |choice|
            @client.send_to_server(Message.new(:move, {:direction => choice}))
        end

        @playing_menu_exchange = define_exchange(:choose_from_list, {:field => :playing_menu, :choices => playing_menu_choices}) do |choice|
            case choice
            when :inspect
                begin_exchange(@inspect_room_exchange)
            when :move
                begin_exchange(@move_exchange)
            #when :act
            end
        end

        begin_exchange(@playing_menu_exchange)
    end

    def playing_menu_choices; [:inspect, :move, :act]; end

    def from_server(message)
        case message.type
        when :move_fail, :move_success
            pass_to_client(message)
            begin_exchange(@playing_menu_exchange)
            return
        end
        super(message)
    end
end
