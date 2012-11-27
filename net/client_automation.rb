require 'net/game_client'
require 'ui/client_interface'

class MessagePair
    attr_reader :from_server, :client_response
    def initialize(from_server, client_response)
        @from_server = from_server
        @client_response = client_response
    end

    def match(msg)
        if Message.match_message(msg, @from_server)
            return :server
        elsif Message.match_message(msg, @client_response)
            return :client
        end
        nil
    end
end

# PairedAutoClient can switch interfaces, being controlled by Automation.
class PairedAutoClient < GameClient
    def initialize(config={})
        super(MetaDataInterface, config)
        @pairs = []
    end

    def push_pair(pair)
        @pairs << pair
    end

    def push_pair(from, resp)
        @pairs << MessagePair.new(from, resp)
    end

    def send_to_client(message)
        if @interface == MetaDataInterface
            super(message)
        else
            puts super(message)
        end
    end
    
    def get_from_client
        context = current_state.get_exchange_context
        # Only one response per context, please.
        return if context == @old_context || context.nil?

        if @interface == MetaDataInterface
            @pairs.each do |pair|
                if pair.match(context) == :server
                    @old_context = context
                    return super(pair.client_response[:input])
                end
            end
            puts "Don't know what to do with #{context.inspect}"
            puts "Switching back to user-mode."
            switch_to_user_mode
            send_to_client(context)
        end
        super(gets.chomp)
    end

    def switch_to_user_mode
        @interface = VerboseInterface
    end
end

$config = {
    :server_ip => "localhost",
    :server_port => PairedAutoClient::DEFAULT_LISTEN_PORT,
    :username => "zphobic",
    :password => "d3rt3rl3rk3r",
    :lobby_name => "test_lobby",
    :lobby_password => "test",
}

Log.setup("Main Thread", "client")
$client = PairedAutoClient.new($config)

signals = ["TERM","INT"]
signals.each do |signal|
    Signal.trap(signal) {
        Log.debug("Caught signal #{signal}")
        $client.stop if $client
    }
end

$client.push_pair({:type => :choose_from_list,  :choices => [:list_lobbies, :join_lobby, :create_lobby, :disconnect]},
                  {:type => :valid_input,       :input => :join_lobby})
$client.push_pair({:type => :text_field,        :field => :lobby_name},
                  {:type => :valid_input,       :input => $config[:lobby_name]})
$client.push_pair({:type => :text_field,        :field => :lobby_password},
                  {:type => :valid_input,       :input => $config[:lobby_password]})

$client.start