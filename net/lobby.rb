require 'game/game_core'
require 'game/descriptors'
require 'util/log'
require 'net/http_server'

# Lobbies group players together with a Game and facilitate communications between the game and the client sockets
class Lobby
    attr_reader :name

    def initialize(name, password_hash, creator, web_server, &block)
        # Credentials
        @name          = name
        @password_hash = password_hash

        # Game administration / socket maintenance / broadcast list
        @users          = {}
        @users[creator] = {:admin => true}
        @default_admin  = creator

        # Local state, basically
        @game_state    = :genesis

        # Game objects
        @game_core     = nil
        @game_args     = {}

        # How the lobby sends messages back to clients (while still using the thread-safe mutexes and methods)
        unless block_given?
            raise "Lobby has no means with which to send client data"
        end
        @send_callback = block

        web_server.add_response(/\/#{@name.escape}\/([^\/]*)/i) do |args|
            "Status page for #{args.first} (in lobby #{@name})"
        end
    end

    def is_admin?(username)
        @users[username][:admin]
    end

    def is_playing?(username)
        @game_core && @game_core.has_active_character?(username)
    end

    def send_to_user(username, message)
        # Sanitize the message
        character = is_playing?(username) ? @game_core.get_character(username) : nil
        message.alter_params do |params|
            Descriptor.describe(params, character)
        end
        @send_callback.call(username, message)
    end

    def send_to_users(list, message)
        list.each do |user|
            send_to_user(user, message)
        end
    end

    def broadcast(message, exemptions=[])
        send_to_users(@users.keys - exemptions, message)
    end

    # Seriously.  LAUGHABLE crypto
    def check_password(hash)
        hash == @password_hash
    end

    def get_game_core
        @game_core
    end

    def add_user(username)
        if @users[username]
            Log.debug("#{username} is already active in the lobby")
            return
        end

        Log.info("#{username} joining #{name}")
        broadcast(Message.new(:user_joins, {:result => username}), [username])
        @users[username] = {}

        # TODO - Add a privelege set so that other users can be granted admin
        if @default_admin == username
            @users[username][:admin] = true
            Log.info("#{username} reclaiming admin privileges")
            broadcast(Message.new(:admin_change, {:result => username}))
        end
    end

    def remove_user(username)
        unless @users[username]
            Log.debug("No user #{username}")
            return
        end

        if is_playing?(username)
            @game_core.remove_character(username)
        end
        @users.delete(username)
        Log.info("#{username} has left #{name}")
        broadcast(Message.new(:user_leaves, {:result => username}))
    end

    def get_user_characters(username)
        character_list = @game_core.get_user_characters(username)
        # TODO - Eventually, we'll want to do some kind of filtering on what sorts of characters are acceptable for this lobby (maximum level, etc)
        character_list
    end

    def set_user_character(username, character_name)
        if @game_state == :genesis
            send_to_user(username, Message.new(:character_not_ready, {:reason => "Game has not been generated"}))
            return
        end

        if @game_state == :playing && is_playing?(username)
            send_to_user(username, Message.new(:character_not_ready, {:reason => "Character already loaded"}))
            return
        end

        character, failures = @game_core.load_character(username, character_name)
        if character
            if @game_state == :playing
                send_to_user(username, Message.new(:begin_playing))
            else
                send_to_user(username, Message.new(:character_ready))
            end
        else
            failure = if failures.empty?
                "Character not found"
            else
                "Character failed to load"
            end
            # FIXME - Inform users when some of their more recent character saves fail to load
            send_to_user(username, Message.new(:character_not_ready, {:reason=>failure}))
        end
    end

    def generate_game(username)
        unless is_admin?(username)
            send_to_user(username, Message.new(:generation_fail, {:reason => :access_denied}))
            return false
        end

        if @game_state == :genesis
            # Create the new game core
            @game_core = GameCore.new
            @game_core.setup(@game_args)
            # Start listening for messages from this core
            Message.register_listener(@game_core, :core, self)

            @game_state = :ready
            Log.info("Game created")
            broadcast(Message.new(:generation_success))
            true
        elsif @game_state == :playing || @game_state == :ready
            send_to_user(username, Message.new(:generation_fail, {:reason => :already_generated}))
            false
        else
            Log.error("Unknown game state")
            send_to_user(username, Message.new(:generation_fail, {:reason => :unknown}))
            false
        end
    end

    def start_game(username)
        unless is_admin?(username)
            send_to_user(username, Message.new(:start_fail, {:reason => :access_denied}))
            return false
        end

        if @game_state == :ready
            @game_state = :playing

            Log.info("Game started")
            broadcast(Message.new(:start_success))

            @users.keys.each do |username|
                if @game_core.has_active_character?(username)
                    send_to_user(username, Message.new(:begin_playing))
                end
            end

            @game_core.start_ticking
        elsif @game_state == :playing
            send_to_user(username, Message.new(:start_fail, {:reason => :already_started}))
            false
        else @game_state == :genesis
            send_to_user(username, Message.new(:start_fail, {:reason => :world_not_generated}))
            false
        end
    end

    def process_message(message, username=nil)
        case message.message_class
        when :lobby; process_lobby_message(message, username)
        when :game;  process_game_message(message, username)
        when :core;  process_core_message(message)
        else 
            Log.error("Lobby doesn't know how to handle message class #{message.message_class}")
        end
    end

    def process_core_message(message)
        case message.type
        when :tick
            Log.debug("Lobby tick", 6)
        when :unit_acts
            @users.keys.each do |username|
                character = @game_core.get_character(username)
                next if character.nil?
                next unless message.position == character.position

                event_properties = message.params.merge(:event_type => action)
                send_to_user(username, Message.new(:game_event, {:description => event_properties}))
            end
        when :object_destroyed
            @users.keys.each do |username|
                character = @game_core.get_character(username)
                next if character.nil?
                next unless message.position == character.position

                event_properties = message.params.merge(:event_type => :object_destroyed)
                send_to_user(username, Message.new(:game_event, {:description => event_properties}))

                if message.target == character
                    Log.info("Character #{character.name} dies!")
                    @game_core.remove_character(username, true)
                    broadcast(Message.new(:user_dies, {:result => username}))
                end
            end
        end
    end

    def process_game_message(message, username)
        unless is_playing?(username)
            Log.error("Can't parse game message for #{username} - user isn't playing yet")
        end

        case message.type
        when :act
            Log.debug("Parsing action message", 8)
            action = nil
            begin
                Log.debug("Performing command", 8)
                character = @game_core.get_character(username)

                results = Commands.do(@game_core, message.command, message.args.merge(:agent => character))
                send_to_user(username, Message.new(:act_success, {:description => results}))
            rescue Exception => e
                Log.debug(["Failed to perform command #{message.command}", e.message, e.backtrace])
                send_to_user(username, Message.new(:act_fail, {:reason => e.message}))
            end
        when :get_link
            send_to_user(username, Message.new(:link, {:result => "/#{@name.escape}/#{username.escape}"}))
=begin
            character = @game_core.get_character(username)
            map_data = @game_core.world.get_map({character.position => :red})
            send_to_user(username, Message.new(:map, {:map_data => map_data}))
=end
        else
            Log.warning("Unhandled game message type #{message.type} received from client")
        end
    end

    def process_lobby_message(message, username)
        case message.type
        when :get_game_params
            # Eventually there will actually *be* game params, at which point we'll want to send them here
            Log.warning("PARTIALLY IMPLEMENTED")
            send_to_user(username, Message.new(:game_params, {:params=>{}}))
        when :generate_game
            generate_game(username)
        when :create_character
            # Basically, this is the event that triggers the character to be saved and used
            # The server isn't involved in the character creation dialog at all, only the committing of that data
            Log.warning("UNIMPLEMENTED")
            send_to_user(username, Message.new(:character_not_ready, {:reason => "Feature unimplemented"}))
        when :list_characters
            if @game_state == :genesis
                send_to_user(username, Message.new(:no_characters, {:reason => "Game not yet generated"}))
            else
                characters = get_user_characters(username)
                if characters.empty?
                    send_to_user(username, Message.new(:no_characters, {:reason => "None found"}))
                else
                    send_to_user(username, Message.new(:character_list, {:characters => characters}))
                end
            end
        when :select_character
            set_user_character(username, message.character_name)
        when :start_game
            start_game(username)
        when :toggle_pause
            Log.warning("UNIMPLEMENTED")
        else
            Log.error("Unhandled lobby message type #{message.type} received from client")
        end
    end
end
