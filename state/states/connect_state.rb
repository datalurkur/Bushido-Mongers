require 'state/state'
require 'state/states/login_state'

class ConnectState < State
    def initialize(client, method)
        super(client, method)

        define_exchange_chain([
            [:server_ip,   :text_field],
            [:server_port, :text_field]
        ]) do
            attempt_connection
        end

        if @client.get(:server_ip) && @client.get(:server_port)
            attempt_connection
        else
            begin_exchange(:server_ip)
        end
    end

    def attempt_connection
        Log.debug("Attempting to connect to #{@client.get(:server_ip)}:#{@client.get(:server_port)}")
        begin
            @client.connect(@client.get(:server_ip), @client.get(:server_port).to_i)
            Log.debug("Connection successful")
            LoginState.new(@client, :set)
        rescue Exception => e
            Log.debug(["Failed to connect", e.message])
            begin_exchange(:server_ip)
        end
    end
end
