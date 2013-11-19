require './net/stack_client'

class LobbyBypassClient < StackClient
    def initialize(config = {})
        super(config)

        # Set up the responses that auto-join or create the lobby, login and start, according to the client config.

        self.stack.set_state(:join_lobby)
        self.stack.specify_response_for(:choose_from_list, :field => :server_menu) do |stack, message|
            if stack.get_state == :join_lobby
                Log.debug("Attempting to join lobby #{config[:lobby_name]}/#{config[:lobby_password]}")
                stack.put_response(:join_lobby)
            else
                Log.debug("Attempting to create lobby #{config[:lobby_name]}/#{config[:lobby_password]}")
                stack.put_response(:create_lobby)
            end
        end
        self.stack.specify_response_for(:text_field, :field => :lobby_name) do |stack, message|
            stack.put_response(config[:lobby_name])
        end
        self.stack.specify_response_for(:text_field, :field => :lobby_password) do |stack, message|
            stack.put_response(config[:lobby_password])
        end
        self.stack.specify_response_for(:join_fail) do |stack, message|
            stack.set_state(:create_lobby)
        end
        self.stack.specify_response_for(:create_fail) do |stack, message|
            config[:lobby_name] += "_"
        end
        [:join_success, :create_success].each do |msg|
            self.stack.specify_response_for(msg) do |stack, message|
                stack.put_response(:generate_game)
            end
        end
        self.stack.specify_response_for(:choose_from_list, :field => :lobby_menu) do |stack, message|
            case stack.get_state
            when :generate_game
                stack.put_response(:generate_game)
            when :start_game
                stack.put_response(:start_game)
            when :create_character
                stack.put_response(:create_character)
            end
        end
        self.stack.specify_response_for(:generation_pending) do |stack, message|
            stack.set_state(:wait_for_gen)
        end
        self.stack.specify_response_for(:generation_success) do |stack, message|
            stack.set_state(:start_game)
        end
        self.stack.specify_response_for(:generation_fail) do |stack, message|
            if message.reason == :already_generated
                stack.set_state(:start_game)
            else
                Log.debug("Couldn't generate world - #{message.reason}")
                self.release_control
            end
        end
        self.stack.specify_response_for(:start_success) do |stack, message|
            stack.set_state(:create_character)
        end
        self.stack.specify_response_for(:start_fail) do |stack, message|
            if message.reason == :already_started
                stack.set_state(:create_character)
            else
                Log.debug("Couldn't start game - #{message.reason}")
                self.release_control
            end
        end
        self.stack.specify_response_for(:text_field, :field => :character_name) do |stack, message|
            stack.put_response(config[:character_name])
        end
        self.stack.specify_response_for(:choose_from_list, :field => :character_archetype) do |stack, message|
            stack.put_response(message.choices.rand)
        end
        self.stack.specify_response_for(:choose_from_list, :field => :character_morphism) do |stack, message|
            stack.put_response(message.choices.rand)
        end
        self.stack.specify_response_for(:choose_from_list, :field => :character_options) do |stack, message|
            stack.put_response(:create)
        end
        self.stack.specify_response_for(:character_ready) do |stack, message|
            stack.clear_state
        end
        self.stack.specify_response_for(:character_not_ready) do |stack, message|
            self.release_control
        end
        self.stack.specify_response_for(:begin_playing) do |stack, message|
            self.release_control
        end
    end
end