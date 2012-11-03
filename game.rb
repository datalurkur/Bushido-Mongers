require 'vocabulary'
require 'ninja'
require 'shogun'
require 'room'
require 'castle'

# Basically the server backend
class Game
    class << self
        def default_config
            {
                :starting_patrol_strength => 3,
                :minimum_players          => 2,
                :maximum_players          => 4,
                :reincarnation_period     => 3,
            }
        end
    end

    attr_reader :state, :round
    def initialize(args={})
        new_game

        @config = Game.default_config.merge(args)

        Message.register_listener(self, Message::NewPlayer)
        Message.register_listener(self, Message::SetPlayerReady)
        Message.register_listener(self, Message::PlayerResigns)

        Message.register_listener(self, Message::UnitDies)

        self
    end

    def players;                  @ready.keys;                                                   end
    def all_players_ready?;       @ready.values.inject(true) { |overall,this| overall && this }; end
    def clear_ready_flags;        players.each { |k| @ready[k] = false };                        end
    def flag_ready(player,state); @ready[player] = state;                                        end

    def parse_message(message)
        case message
        when Message::NewPlayer
            begin
                (raise "Players cannot join during #{@state}")        unless (@state == :join || @state == :pending)
                (raise "Player, castle, and ninja name are required") unless (message.player && message.castle && message.ninja)
                (raise "Maximum number of players reached")           if     (players.size >= @config[:maximum_players])
                (raise "Player name taken")                           if     (players.include?(message.player))

                debug("Player joins: #{message.player}")
                add_player(message.player,message.castle,message.ninja)
                Message.send(Message::PlayerJoins.new(message.player,@castles[message.player].name,@ninjas[message.player].name))

                if players.size >= @config[:minimum_players]
                    game_pending
                end
            rescue Exception => e
                debug(["Player rejected:",e.message,e.backtrace])
                Message.send(Message::PlayerRejected.new(message.player,e))
            end
        when Message::PlayerResigns
            player_defeated(message.player,"resigned")
        when Message::SetPlayerReady
            flag_ready(message.player, message.state)
            if all_players_ready?
                if @state == :pending
                    game_starting
                elsif @state == :playing
                    tick
                    Message.send(Message::NextRound.new)
                else
                    raise "Unknown case - player flagged as ready during #{@state}"
                end
                clear_ready_flags
            end
        when Message::UnitDies
            case message.agent
            when Shogun
                player_defeated(player,"shogun slain by #{message.slayer}")
            when Ninja
                @reincarnating[player] = @config[:reincarnation_period]
                Message.send(Message::News.new([message.agent.owner,message.slayer.owner],"#{message.agent.name} was slain by #{message.slayer.name}"))
            end
        end
    end

    def new_game
        @ready = {}
        @ninjas  = {}
        #@shoguns = {} # Add this later, obviously important
        #@patrols = {} # Not worrying about this for now
        @castles = {}

        @reincarnating = {}

        @border = Room.new("Borderlands")
        @state  = :join
    end

    def game_pending
        debug("Minimum number of players reached (#{players.size})")
        @state = :pending
        Message.send(Message::GamePending.new)
    end

    def game_starting
        @state = :playing
        @round = 1
        Message.send(Message::GameStarts.new)
    end

    def player_defeated(player,reason)
        @ninjas.delete(player)
        @ready.delete(player)
        if @state != :playing
            @castles.delete(player)
            (@state = :join) if (@state == :pending && players.size < @config[:minimum_players])
        end
        Message.send(Message::PlayerDefeated.new(player,reason))

        if @ready.size == 1
            # Game over!
            Message.send(Message::GameEnds.new(@ready.keys.first))
            new_game
        end
    end

    def active_castles; @castles.values.collect(&:name); end
    def active_ninjas; @ninjas.values.collect(&:name); end
    def castle(player); @castles[player]; end
    def ninja(player); @ninjas[player]; end

private
    def add_player(player,castle,ninja)
        @ready[player]   = false
        @castles[player] = Castle.new(castle,player,@border)

        ninja_start      = @castles[player].random_room
        ninja            = Ninja.new(ninja,player,ninja_start)
        @ninjas[player]  = ninja
    end

    def tick
        debug("Round #{@round} ticking",2)

        # Perform ninja actions
        @ninjas.each_value do |ninja|
            ninja.update
        end

        # Update castle (accumulate wealth, etc)
        @castles.each_value do |castle|
            castle.update
        end

        # Do ninja reincarnation
        revived = []
        @reincarnating.each_key do |player|
            @reincarnating[player] -= 1
            if @reincarnating[player] <= 0
                location = @castles[player].random_room
                @ninjas[player].revive(location)
                Message.send(Message::News.new(player,"#{@ninjas[player].name} reincarnates at the #{location}"))
                revived << player
            end
        end
        revived.each { |r| @reincarnating.delete(revived) }

        @round += 1
    end
end
