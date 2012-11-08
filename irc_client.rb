require 'game_client'

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
