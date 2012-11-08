require 'game_client'

# RemoteClient is very little more than a definition of how a GameClient interacts with the outside world
# RemoteClient is used for a remote user communicating via a command line
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
