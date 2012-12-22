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
        when :move_fail, :move_success, :act_fail, :act_success
            pass_to_client(message)
            begin_exchange(@playing_menu_exchange)
            return
        end
        super(message)
    end

    def from_client(message)
        unless process_exchange(message, :client)
            if message.type == :raw_command
                # Parse the command into an action
                # FIXME - Hey zphobic!  Make this more grammatical!
                Log.debug("Parsing command #{message.command}")
                pieces = message.command.split(/\s+/).collect { |i| i.to_sym }

                # Join any conjunctions together
                while (i = pieces.index(:and))
                    first_part = (i > 1)               ? pieces[0...(i-1)] : []
                    last_part  = (i < pieces.size - 2) ? pieces[(i+1)..-1] : []
                    first_part + [pieces[(i-1)..(i+1)]] + last_part
                end
                
                # Find the verb
                command = pieces.slice!(0)

                # Find the tool
                tool = if (tool_index = pieces.index(:with))
                    pieces.slice!(tool_index,2).last
                end

                # Find the location
                location = if (location_index = pieces.index(:at))
                    pieces.slice!(location_index,2).last
                end

                # Find materials
                materials = if (materials_index = pieces.index(:using))
                    pieces.slice!(materials_index,2).last
                end

                # Whatever is left over is the target
                target = pieces.slice!(0)

                if pieces.size > 0
                    Log.debug(["Ignoring potentially important syntactic pieces", pieces])
                end

                Log.debug("Acting!")
                @client.send_to_server(Message.new(:act, {:command => command, :args => {
                    :tool      => tool,
                    :location  => location,
                    :materials => materials,
                    :target    => target
                }}))
            else
                Log.debug(["Unhandled message #{message.type} encountered during client processing for #{self.class}", caller])
            end
        end
    end
end
