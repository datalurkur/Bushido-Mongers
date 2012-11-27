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
