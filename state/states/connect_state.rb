require './state/state'
require './state/states/login_state'

class ConnectState < State
    def initialize(client, method)
        super(client, method)

        @connect_exchange = define_exchange_chain([
            [:text_field, {:field => :server_hostname}],
            [:text_field, {:field => :server_port}]
        ]) do
            attempt_connection
        end

        if @client.get(:server_hostname) && @client.get(:server_port)
            attempt_connection
        else
            begin_exchange(@connect_exchange)
        end
    end

    def attempt_connection
        Log.debug("Attempting to connect to #{@client.get(:server_hostname)}:#{@client.get(:server_port)}")
        begin
            @client.connect(@client.get(:server_hostname), @client.get(:server_port).to_i)
            Log.debug("Connection successful")
            LoginState.new(@client, :set)
        rescue Exception => e
            Log.debug(["Failed to connect", e.message])
            begin_exchange(@connect_exchange)
        end
    end
end
