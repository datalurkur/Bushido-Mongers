require 'state/state'

class ConnectState < State
    def initialize(client)
        @client = client
    end

    def from_client(message)
    end

    def from_server(message)
    end
end
