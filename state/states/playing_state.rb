require 'state/state'

class PlayingState < State
    def initialize(client)
        super(client)
    end

    def from_server(message)
        case message.type
        when :link
            pass_to_client(message)
            return
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
                Log.debug("Parsing command #{message.command.inspect}", 6)

                if message.command.empty?
                    Log.debug("No command data given", 4)
                elsif message.command[0,1] == "/"
                    if message.command.match(/link/)
                        @client.send_to_server(Message.new(:get_link))
                    else
                        Log.debug("Unrecognized command #{message.command}", 4)
                    end
                else
                    pieces = message.command.split(/\s+/).collect(&:to_sym)
                    act_args = Words.decompose_command(pieces)

                    @client.send_to_server(Message.new(:act, act_args))
                end
            else
                Log.debug(["Unhandled message #{message.type} encountered during client processing for #{self.class}", caller])
            end
        end
    end
end
