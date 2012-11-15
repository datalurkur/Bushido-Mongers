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
        @users         = [creator]
        @default_admin = creator
        @admin         = creator

        # Local state, basically
        @game_state    = :genesis
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

    def is_admin?(user)
        @admin == user
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
        send_to_users(@users - exemptions, message)
    end

    # Seriously.  LAUGHABLE crypto
    def check_password(hash)
        hash == @password_hash
    end

    def add_user(username)
        Log.debug("#{username} joining #{name}")
        broadcast(Message.new(:user_joins, {:username => username}))
        @users << username

        if @default_admin == username && @admin != username
            @admin = username
            Log.debug("#{username} reclaiming admin priveleges")
            broadcast(Message.new(:admin_change, {:admin => @admin}))
        end
    end

    def remove_user(username)
        @users.delete(username)
        Log.debug("#{username} has left #{name}")
        broadcast(Message.new(:user_leaves, {:username => username}))

        if @admin == username
            @admin = @users.first
            Log.debug("Passing admin rights to #{@admin}")
            broadcast(Message.new(:admin_change, {:admin => @admin}))
        end
    end

    def generate_game(username)
        unless is_admin?(username)
            send_to_user(username, Message.new(:generation_fail, {:reason => "You are not the lobby admin"}))
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
            send_to_user(username, Message.new(:start_fail, {:reason => "You are not the lobby admin"}))
            return false
        end

        if @game_state == :ready
            @game_state = :playing
            Log.debug("Game started")
            broadcast(Message.new(:start_success))
        else
            Log.debug("Failed to start game - Lobby is not in :ready state")
            send_to_user(username, Message.new(:start_fail, {:reason => "Lobby is not :ready (#{@game_state})"}))
            false
        end
    end
end
