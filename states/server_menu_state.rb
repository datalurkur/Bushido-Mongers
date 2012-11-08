require 'state'

class ServerMenuState < State
    def initialize(client)
        super(client)
        @client.send_to_client(Message.new(:notify, {:text=>"You have connected to the server as #{@client.get(:name)}"}))
    end
end
