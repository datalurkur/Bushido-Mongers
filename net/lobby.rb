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

        # Players are filled in as users create or select characters
        @players       = {}
    end

    def is_admin?(username)
        @users[username][:admin]
    end

    def is_playing?(username)
        @game_core && @game_core.has_player?(username)
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
        Log.debug("#{username} joining #{name}")
        broadcast(Message.new(:user_joins, {:username => username}), [username])
        @users[username] = {}

        # TODO - Add a privelege set so that other users can be granted admin
        if @default_admin == username
            @users[username][:admin] = true
            Log.debug("#{username} reclaiming admin priveleges")
            broadcast(Message.new(:admin_change, {:admin => username}))
        end
    end

    def remove_user(username)
        if is_playing?(username)
            # Save the player
            Player.save_character(username, @game_core.get_player(username))
            @game_core.remove_player(username)
        end
        @users.delete(username)
        Log.debug("#{username} has left #{name}")
        broadcast(Message.new(:user_leaves, {:username => username}))
    end

    def get_user_characters(username)
        character_list = Player.get_characters_for(username)
        # TODO - Eventually, we'll want to do some kind of filtering on what sorts of characters are acceptable for this lobby (maximum level, etc)
        character_list
    end

    def set_user_character(username, character_name)
        # TODO - Do we want to deal with switching characters mid-game?  Is this allowed?
        raise "User already active" if @game_state == :playing && is_playing?(username)

        # Get a list of the user's saved characters
        character_list = Player.get_characters_for(username)

        # See if this character is in that list
        characters = character_list.select { |c| c == character_name }
        if characters.empty?
            failure = "No character named #{character_name} exists for #{username}"
            Log.debug(failure)
            send_to_user(username, Message.new(:character_not_ready, {:reason=>failure}))
        else
            Log.debug("#{username} selects character named #{character_name}")

            # Gather all the saves for this character
            character_history = Player.get_character_history(username, character_name)

            # Try to load saves (starting with the latest)
            character_history.each do |cdata|
                begin
                    player = Player.load_character(username, cdata[:filename])
                    @users[username][:pending_character] = player
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
            send_to_user(username, Message.new(:generation_fail, {:reason => "You are not the game admin"}))
            return false
        end

        if @game_state == :genesis
            @game_core = GameCore.new(@game_args)
            @game_state = :ready
            Log.debug("Game created")
            broadcast(Message.new(:generation_success))
            true
        else
            Log.debug("Lobby is not in :genesis state")
            send_to_user(username, Message.new(:generation_fail, {:reason => "Lobby is not in :genesis (#{@game_state})"}))
            false
        end
    end

    def start_game(username)
        unless is_admin?(username)
            send_to_user(username, Message.new(:start_fail, {:reason => "You are not the game admin"}))
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
        else
            Log.debug("Failed to start game - Lobby is not in :ready state")
            send_to_user(username, Message.new(:start_fail, {:reason => "Lobby is not :ready (#{@game_state})"}))
            false
        end
    end

    def process_message(username, message)
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
