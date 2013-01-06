require 'state/state'

class PlayingState < State
    def initialize(client)
        super(client)
    end

    def from_server(message)
        case message.type
        when :user_joins, :user_leaves, :admin_change
            pass_to_client(message)
            return
        when :act_fail
            # FIXME - Use a sentence to describe the result
            pass_to_client(message)
            return
        when :act_success
            @client.send_to_client(Message.new(:properties, {:field => :action_results, :properties => message.description}))
            return
        when :game_event
            @client.send_to_client(Message.new(:properties, {:field => :game_event, :properties => message.description}))
            return
        when :user_dies
            pass_to_client(message)
            @client.set_state(LobbyState.new(@client)) if message.result == @client.get(:username)
            return
        end
        super(message)
    end

    def from_client(message)
        unless process_exchange(message, :client)
            if message.type == :raw_command
                # Parse the command into an action
                # FIXME - Hey zphobic!  Make this more grammatical!
                Log.debug("Parsing command #{message.command.inspect}")
                pieces = message.command.split(/\s+/).collect(&:to_sym)

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
