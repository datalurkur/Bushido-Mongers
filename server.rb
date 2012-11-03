require 'game'
require 'client'

class Server
    attr_reader :running

    def initialize
        Message.register_listener(self, Message::RegistrationBegins)
        Message.register_listener(self, Message::PlayerJoins)
        Message.register_listener(self, Message::SetPlayerReady)
        Message.register_listener(self, Message::PlayerRejected)
        Message.register_listener(self, Message::PlayerDefeated)
        Message.register_listener(self, Message::GamePending)
        Message.register_listener(self, Message::GameStarts)
        Message.register_listener(self, Message::NextRound)
        Message.register_listener(self, Message::GameEnds)
        Message.register_listener(self, Message::News)

        @game    = Game.new
        @running = false
        @clients = {}

        self
    end

    def send(client,message); raise "Send must be implemented by a subclass";  end

    def start
        debug("Starting server")
        @running = true
    end

    def stop
        debug("Stopping server")
        msg_to_all_players("Server is shutting down")
        @running = false
    end

    def save(name)
        raise "Save feature not implemented"
    end

    def load(name)
        raise "Load feature not implemented"
    end

    def msg(client,message)
        return if message.nil?
        (Array === message) ? (message.each { |m| send(client,m) }) : send(client,message)
    end

    def process_client_command(client,message)
        unless @clients[client]
            @clients[client] ||= Client.new(@game)
            msg(client,"Welcome, #{client}!")
            results = @clients[client].set_state(:setup)
            msg(client,results)
        else
            results = @clients[client].process(message)
            msg(client,results)
        end
    end

    def all_players;    @clients.keys                                      end
    def active_players; @clients.keys.select { |k| @clients[k].active? };  end

    def msg_to_all_players(message);    all_players.each    { |client| msg(client,message) }; end
    def msg_to_active_players(message); active_players.each { |client| msg(client,message) }; end

    def get_client(player)
        p = @clients.values.select { |i| i.player == player }
        raise "Duplicate players detected" if p.size > 1
        raise "Error locating player" if p.empty?
        p[0]
    end

    def update_client_state(filter,update)
        eligible_clients = @clients.keys.select do |client_key|
            c = @clients[client_key]
            case filter
            when Array;  filter.include?(c.state)
            when Symbol; filter == c.state
            when Client; filter == c
            end
        end
        eligible_clients.each do |client_key|
            results = @clients[client_key].set_state(update)
            msg(client_key, results)
        end
    end

    def update_clients_for_next_round
        active_players.each do |client_name|
            debug("Updating #{client_name}",4)
            client = @clients[client_name]
            
            # Handle news
            client.news do |news|
                msg(client_name, news)
            end
            client.clear_news
        end
    end

    def parse_message(message)
        case message
        when Message::RegistrationBegins
            msg_to_all_players("Waiting for players to join.")
            update_client_state([:pending,:playing,:defeated], :waiting)
        when Message::SetPlayerReady
            msg_to_all_players("#{message.player} is#{message.state ? "" : " not"} ready")
        when Message::PlayerJoins
            msg_to_all_players("#{message.player} has joined the game.")
            update_client_state(get_client(message.player), :waiting)
        when Message::PlayerResigns
            update_client_state(get_client(message.player), (@game.state == :playing) ? :defeated : :setup)
            msg_to_all_players("#{message.player} has resigned.")
        when Message::PlayerRejected
            msg(message.player,"Join request rejected - #{message.reason}")
        when Message::PlayerDefeated
            msg_to_all_players("#{message.player} has been defeated - #{message.reason}")
            update_client_state(get_client(message.player), :defeated)
        when Message::GamePending
            msg_to_all_players("There are enough players to begin the game; type \"ready\" to start the game (all players must be ready).")
            update_client_state(:waiting,:pending)
        when Message::GameStarts
            msg_to_all_players("The game has begun!")
            update_client_state(:pending,:playing)
            update_clients_for_next_round
        when Message::GameEnds
            msg_to_all_players("The game has ended, all honor to the victor, #{message.winner}!")
        when Message::NextRound
            msg_to_all_players("The round has ended.")
            update_clients_for_next_round
        when Message::News
            message.recipients.each { |r| get_client(r).add_news(message.message) }
        end
    end
end
