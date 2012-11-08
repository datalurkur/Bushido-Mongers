require 'state'

class LobbyState < State
    def initialize(client)
        super(client)
        @client.send_to_client(Message.new(:notify, {:text=>"You have entered the lobby"}))
    end
end
