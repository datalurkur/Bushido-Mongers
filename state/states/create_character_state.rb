require './state/state'

class CreateCharacterState < State
    def setup_exchanges
        @required_creation = define_exchange_chain([
            [:text_field,       {:field => :name}],
            [:server_query,     {:query_method => :get_character_opts, :query_params => {:property => :race}}],
            [:choose_from_list, {:field => :race, :choices_from => :options}],
            [:server_query,     {:query_method => :get_character_opts, :query_params => {:property => :gender}}],
            [:choose_from_list, {:field => :gender, :choices_from => :options}],
        ]) { begin_exchange(@optional_creation) }

        @optional_creation = define_exchange(:choose_from_list, {:field => :optional, :choices =>
            # TODO - Figure out how to implement attribute and skill modification
            #[:modify_attribute, :modify_skill, :create, :cancel]}) do |choice|
            [:create, :cancel]}) do |choice|
            case choice
            when :create
                @client.send_to_server(Message.new(:create_character, {:attributes =>
                    {
                        :name   => @client.get(:name),
                        :gender => @client.get(:gender),
                        :race   => @client.get(:race)
                    }
                }))
            when :cancel; @client.pop_state
            end
        end
    end

    def make_current
        begin_exchange(@required_creation)
    end

    def from_server(message)
        case message.type
        when :character_ready
            pass_to_client(message)
            PlayingState.new(@client)
        when :character_not_ready
            pass_to_client(message)
            begin_exchange(@required_creation)
        else
            super(message)
        end
    end
end
