require './state/state'

class CreateCharacterState < State
    def setup_exchanges
        @character_name = define_exchange(:text_field, {:field => :character_name}) do
            @client.send_to_server(Message.new(:set_character_opt, {
                :property => :name,
                :value    => @client.get(:character_name)
            }))
            @next_exchange = @character_archetype
        end

        @character_archetype = define_exchange_chain([
            [:server_query,     {:query_method => :get_character_opts, :query_params => {:property => :archetype}}],
            [:choose_from_list, {:field => :character_archetype, :choices_from => :options}],
        ]) do
            @client.send_to_server(Message.new(:set_character_opt, {
                :property => :archetype,
                :value    => @client.get(:character_archetype)
            }))
            @next_exchange = @character_morphism
        end

        @character_morphism = define_exchange_chain([
            [:server_query,     {:query_method => :get_character_opts, :query_params => {:property => :morphism}}],
            [:choose_from_list, {:field => :character_morphism, :choices_from => :options}],
        ]) do
            @client.send_to_server(Message.new(:set_character_opt, {
                :property => :morphism,
                :value    => @client.get(:character_morphism)
            }))
            @next_exchange = @optional_creation
        end

        @optional_creation = define_exchange(:choose_from_list, {:field => :character_options, :choices =>
            # TODO - Figure out how to implement attribute and skill modification
            #[:modify_attribute, :modify_skill, :create, :cancel]}) do |choice|
            [:create, :cancel]}) do |choice|
            case choice
            when :create
                @client.send_to_server(Message.new(:create_character, {
                    :attributes => {}
                }))
            when :cancel; @client.pop_state
            end
        end
    end

    def make_current
        begin_exchange(@character_name)
    end

    def from_server(message)
        case message.type
        when :opt_set_ok
            pass_to_client(message)
            begin_exchange(@next_exchange)
        when :opt_set_failed
            pass_to_client(message)
            begin_exchange(@previous_exchange || @character_name)
        when :character_ready
            pass_to_client(message)
            @client.pop_state
        when :character_not_ready
            pass_to_client(message)
            @client.pop_state
        else
            super(message)
        end
    end
end
