require 'net/game_client'

# Acts in place of a normal remote client for IRC users, interacting with the IRCConduit instead of the console (or whatever)
class IRCClient < GameClient
    def initialize(port,name)
        super("localhost",port,SlimInterface,{:username=>name})
    end

    def send_to_client(message)
        text = super(message)
        IRCConduit.puts(get(:name),text)
    end

    # Called from a thread in ClientBase
    def get_from_client
        text = IRCConduit.gets(get(:name))
        super(text)
    end
end