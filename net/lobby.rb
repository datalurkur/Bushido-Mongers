require 'util/log'

# Lobbies group players together with a Game and facilitate communications between the game and the client sockets
class Lobby
    attr_reader :name

    def initialize(name,password_hash)
        @name          = name
        @password_hash = password_hash

        @users         = []
    end

    # Seriously.  LAUGHABLE crypto
    def check_password(hash)
        hash == @password_hash
    end

    def add_user(username)
        Log.debug("User #{username} joining lobby #{name}")
        @users << username
    end
end
