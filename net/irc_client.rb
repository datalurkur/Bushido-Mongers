require './net/game_client'
require './ui/client_interface'

# Acts in place of a normal remote client for IRC users, interacting with the IRCConduit instead of the console (or whatever)
class IRCClient < GameClient
    def initialize(port, name)
        super(SlimInterface, {:username=>name})
        connect("localhost", port)
        start(LoginState)
    end

    def send_to_client(message)
        text = super(message)
        IRCConduit.puts(get(:username), text)
    end

    def get_client_stream
        IRCConduit.read_pipe(get(:username))
    end

    # Called from a thread in ClientBase
    def get_from_client
        text = IRCConduit.gets(get(:username))
        super(text)
    end
end
