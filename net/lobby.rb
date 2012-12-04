require 'game/game_core'
require 'util/log'

# Lobbies group players together with a Game and facilitate communications between the game and the client sockets
class Lobby
    attr_reader :name

    def initialize(name,password_hash,creator,&block)
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
    end

    def is_admin?(username)
        @users[username][:admin]
    end

    def is_playing?(username)
        @game_core && @game_core.has_active_character?(username)
    end

    def send_to_user(user, message)
        @send_callback.call(user, message)
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

        Log.debug("#{username} joining #{name}")
        broadcast(Message.new(:user_joins, {:result => username}), [username])
        @users[username] = {}

        # TODO - Add a privelege set so that other users can be granted admin
        if @default_admin == username
            @users[username][:admin] = true
            Log.debug("#{username} reclaiming admin priveleges")
            broadcast(Message.new(:admin_change, {:result => username}))
        end
    end

    def remove_user(username)
        unless @users[username]
            Log.debug("No user #{username}")
            return
        end

        if is_playing?(username)
            # Save the character
            Character.save(username, @game_core.get_character(username))
            @game_core.remove_player(username)
        end
        @users.delete(username)
        Log.debug("#{username} has left #{name}")
        broadcast(Message.new(:user_leaves, {:result => username}))
    end

    def get_user_characters(username)
        character_list = Character.get_characters_for(username)
        # TODO - Eventually, we'll want to do some kind of filtering on what sorts of characters are acceptable for this lobby (maximum level, etc)
        character_list
    end

    def set_user_character(username, character_name)
        # TODO - Do we want to deal with switching characters mid-game?  Is this allowed?
        raise "User already active" if @game_state == :playing && is_playing?(username)

        # Get a list of the user's saved characters
        character_list = Character.get_characters_for(username)

        # See if this character is in that list
        characters = character_list.select { |c| c == character_name }
        if characters.empty?
            failure = "No character named #{character_name} exists for #{username}"
            Log.debug(failure)
            send_to_user(username, Message.new(:character_not_ready, {:reason=>failure}))
        else
            Log.debug("#{username} selects character named #{character_name}")

            # Gather all the saves for this character
            character_history = Character.get_history(username, character_name)

            # Try to load saves (starting with the latest)
            character_history.each do |cdata|
                begin
                    character = Character.load(username, cdata[:filename])
                    @users[username][:pending_character] = character
                    break
                rescue Exception => e
                    # This one failed to load, try the next one
                    Log.debug(["Failed to load character with timestamp #{cdata[:timestamp]}", e.message])
                end
            end

            # Send a failure if we couldn't load any of the saves
            unless @users[username][:pending_character]
                failure = "No valid saves for character"
                Log.debug(failure)
                send_to_user(username, Message.new(:character_not_ready, {:reason=>failure}))
                return
            end

            send_to_user(username, Message.new(:character_ready))

            if @game_state == :playing
                commit_character_choice(username)
            end
        end
    end

    def commit_character_choice(username) 
        @game_core.add_player(username, @users[username][:pending_character])
        @users[username][:pending_character] = nil
        send_to_user(username, Message.new(:begin_playing))
    end

    def generate_game(username)
        unless is_admin?(username)
            send_to_user(username, Message.new(:generation_fail, {:reason => :access_denied}))
            return false
        end

        if @game_state == :genesis
            # Create the new game core
            @game_core = GameCore.new(@game_args)
            # Start listening for messages from this core
            Message.register_listener(@game_core, :core, self)

            @game_state = :ready
            Log.debug("Game created")
            broadcast(Message.new(:generation_success))
            true
        elsif @game_state == :playing || @game_state == :ready
            send_to_user(username, Message.new(:generation_fail, {:reason => :already_generated}))
            false
        else
            Log.debug("Funky - unknown game state here")
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

            Log.debug("Game started")
            broadcast(Message.new(:start_success))

            @users.each do |username,user|
                if user[:pending_character]
                    commit_character_choice(username)
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
            Log.debug("Unhandled class of client message: #{message.message_class}")
        end
    end

    def process_core_message(message)
        case message.type
        when :tick
            Log.debug("Lobby tick")
        end
    end

    def process_game_message(message, username)
        case message.type
        when :inspect_room
            room = @game_core.get_character(username).position
            send_to_user(username, Message.new(:room_info, {
                :name     => room.name,
                :keywords => room.keywords,
                :contents => room.contents,
                :exits    => room.connected_directions,
            }))
        when :move
            character = @game_core.get_character(username)
            result    = character.move(message.direction)
            if result.nil?
                send_to_user(username, Message.new(:move_success))
            else
                send_to_user(username, Message.new(:move_fail, {:reason => result}))
            end
        else
            Log.debug("Unhandled game message type #{message.type} received from client")
        end
    end

    def process_lobby_message(message, username)
        case message.type
        when :get_game_params
            # Eventually there will actually *be* game params, at which point we'll want to send them here
            Log.debug("PARTIALLY IMPLEMENTED")
            send_to_user(username, Message.new(:game_params, {:params=>{}}))
        when :generate_game
            generate_game(username)
        when :create_character
            # Basically, this is the event that triggers the character to be saved and used
            # The server isn't involved in the character creation dialog at all, only the committing of that data
            Log.debug("UNIMPLEMENTED")
            send_to_user(username, Message.new(:character_not_ready, {:reason=>"Feature unimplemented"}))
        when :list_characters
            send_to_user(username, Message.new(:character_list, {:characters=>get_user_characters(username)}))
        when :select_character
            set_user_character(username, message.character_name)
        when :start_game
            start_game(username)
        when :toggle_pause
            Log.debug("UNIMPLEMENTED")
        else
            Log.debug("Unhandled lobby message type #{message.type} received from client")
        end
    end
end
