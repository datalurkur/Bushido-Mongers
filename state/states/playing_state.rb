require './state/state'

class PlayingState < State
    def setup_exchanges
        @clarification = define_exchange(:text_field, {:field => :clarification}) do |data|
            Log.info("Clarified : #{data.inspect}")
            @client.send_to_server(Message.new(:clarification, {:missing_param => data}))
        end
    end
    def make_current; end

    def from_server(message)
        case message.type
        when :command_reply
            pass_to_client(message)
        # It will likely be useful in the future to make this stand out as a legit URL, but since we're in the CLI...
        #when :link
            #@client.send_to_client(Message.new(:properties, {:field => :server_link, :properties => {:host => @client.get(:server_hostname), :uri => message.uri}}))
        when :user_joins, :user_leaves, :admin_change
            pass_to_client(message)
        when :act_clarify
            pass_to_client(message)
            begin_exchange(@clarification) if(message.missing_params.size <= 1)
        when :act_fail, :save_pending, :save_fail, :save_success
            pass_to_client(message)
        when :act_success
            @client.send_to_client(Message.new(:properties, {:field => :action_results, :properties => message.description}))
        when :game_event
            @client.send_to_client(Message.new(:properties, {:field => :game_event, :properties => message.description}))
        when :user_dies
            pass_to_client(message)
            @client.set_state(LobbyState.new(@client)) if message.result == @client.get(:username)
        else
            super(message)
        end
    end

    def from_client(message)
        unless process_exchange(message, :client)
            if message.type == :raw_command
                # Parse the command into an action
                Log.debug("Parsing command #{message.command.inspect}", 6)

                if message.command.empty?
                    Log.debug("No command data given", 4)
                elsif message.command[0,1] == "/"
                    case message.command
                    when /quit/
                        @client.stop
                    else
                        @client.send_to_server(Message.new(:command, :text => message.command[1..-1]))
                    end
                else
                    @client.send_to_server(Message.new(:act, :command => message.command))
                end
            else
                Log.debug(["Unhandled message #{message.type} encountered during client processing for #{self.class}", caller])
            end
        end
    end
end
