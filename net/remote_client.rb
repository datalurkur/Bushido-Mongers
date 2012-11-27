require 'net/game_client'
require 'ui/client_interface'

# RemoteClient is very little more than a definition of how a GameClient interacts with the outside world
# RemoteClient is used for a remote user communicating via a command line
class RemoteClient < GameClient
    def initialize(config={})
        super(VerboseInterface,config)
    end

    def send_to_client(message)
        puts super(message)
    end

    def get_from_client
        super(gets.chomp)
    end
end
