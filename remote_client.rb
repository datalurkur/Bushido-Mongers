require 'game_client'

class RemoteClient < GameClient
    def initialize(ip,port)
        super(ip,port,VerboseInterface)
    end

    def send_to_client(message)
        puts super(message)
    end

    # Called from a thread in ClientBase
    def get_from_client
        super(gets.chomp)
    end
end
