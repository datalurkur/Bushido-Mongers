require './game/cores/default'
require './game/descriptors'
require './http/http_server'

# Lobbies group players together with a Game and facilitate communications between the game and the client sockets
class Lobby
    attr_reader :name

    def initialize(name, password_hash, creator, &block)
        # Credentials
        @name           = name
        @password_hash  = password_hash

        # Game administration / socket maintenance / broadcast list
        @users          = {}
        @users[creator] = {:admin => true}
        @default_admin  = creator

        # Local state, basically
        @game_state     = :genesis

        # Game objects
        @game_core      = nil
        @game_args      = {}

        # How the lobby sends messages back to clients (while still using the thread-safe mutexes and methods)
        raise(ArgumentError, "No send callback passed to lobby (block required).") unless block_given?
        @send_callback = block
    end

    def user_list
        @users.keys.select { |user| is_playing?(user) }
    end

    def game_state
        @game_state
    end

    def is_admin?(username)
        @users[username][:admin]
    end

    def is_playing?(username)
        @game_core && @game_core.has_active_character?(username)
    end

    def send_to_user(username, message)
        character = is_playing?(username) ? @game_core.get_character(username) : nil
        message.alter_params do |params|
            Descriptor.describe(params, character)
        end

        if !@send_callback.call(username, message)
            Log.debug("No socket for user #{username}, client likely disconnected")
            # No socket for user, start the countdown until they're booted from the game
            @users[username][:timeout] ||= Time.now

            # TODO - Read this from a config or something
            timeout = 60
            if (Time.now - @users[username][:timeout]) > timeout
                # Boot the user
                Log.info("#{username} timed out (#{timeout} seconds)")
                remove_user(username)
            end
        elsif @users[username][:timeout]
            @users[username].delete[:timeout]
        end
    end

    def send_to_users(list, message)
        list.each do |user|
            send_to_user(user, message)
        end
    end

    def broadcast(message, exemptions=[])
        send_to_users(@users.keys - exemptions, message)
    end

    # Seriously.  LAUGHABLE crypto
    def check_password(hash)
        hash == @password_hash
    end

    def get_game_core
        @game_core
    end

    def add_user(username)
        if @users[username]
            Log.debug("#{username} is already active in the lobby")
            return
        end

        Log.info("#{username} added to #{name}")
        broadcast(Message.new(:user_joins, {:result => username}), [username])
        @users[username] = {}

        # TODO - Add a privilege set so that other users can be granted admin
        if @default_admin == username
            @users[username][:admin] = true
            Log.info("#{username} reclaiming admin privileges")
            broadcast(Message.new(:admin_change, {:result => username}))
        end
    end

    def remove_user(username)
        unless @users[username]
            Log.debug("No user #{username}")
            return
        end

        if is_playing?(username)
            @game_core.remove_character(username)
        end
        @users.delete(username)
        Log.info("#{username} was removed from #{name}")
        broadcast(Message.new(:user_leaves, {:result => username}))
    end

    def get_user_characters(username)
        character_list = @game_core.get_user_characters(username)
        # TODO - Eventually, we'll want to do some kind of filtering on what sorts of characters are acceptable for this lobby (maximum level, etc)
        character_list
    end

    def set_user_character(username, character_name)
        if @game_state == :genesis
            send_to_user(username, Message.new(:character_not_ready, {:reason => "Game has not been generated"}))
            return
        end

        if @game_state == :playing && is_playing?(username)
            send_to_user(username, Message.new(:character_not_ready, {:reason => "Character already loaded"}))
            return
        end

        character, failures = @game_core.load_character(self, username, character_name)
        if character
            send_to_user(username, Message.new(:character_ready))
            if @game_state == :playing
                send_to_user(username, Message.new(:begin_playing))
            end
        else
            failure = if failures.empty?
                "Character not found"
            else
                "Character failed to load"
            end
            # FIXME - Inform users when some of their more recent character saves fail to load
            send_to_user(username, Message.new(:character_not_ready, {:reason=>failure}))
        end
    end

    def generate_game(username)
        unless is_admin?(username)
            send_to_user(username, Message.new(:generation_fail, {:reason => :access_denied}))
            return false
        end

        if @game_state == :genesis
            @game_state = :generating

            # Create the new game core
            @game_core = DefaultCore.new
            @game_core.setup(@game_args)
            # Start listening for messages from this core
            Message.register_listener(@game_core, :core, self)
            Message.register_listener(@game_core, :tick, self)

            @game_state = :ready
            Log.info("Game created")
            broadcast(Message.new(:generation_success))
            true
        elsif @game_state == :generating
            send_to_user(username, Message.new(:generation_fail, {:reason => :generation_in_progress}))
            false
        elsif @game_state == :playing || @game_state == :ready
            send_to_user(username, Message.new(:generation_fail, {:reason => :already_generated}))
            false
        else
            Log.error("Unknown game state")
            send_to_user(username, Message.new(:generation_fail, {:reason => :unknown}))
            false
        end
    end

    def start_game(username)
        unless is_admin?(username)
            send_to_user(username, Message.new(:start_fail, {:reason => :access_denied}))
            return false
        end

        if @game_state == :ready
            @game_state = :playing

            Log.info("Game started")
            broadcast(Message.new(:start_success))

            @users.keys.each do |username|
                if @game_core.has_active_character?(username)
                    send_to_user(username, Message.new(:begin_playing))
                end
            end

            @game_core.start_ticking
        elsif @game_state == :playing
            send_to_user(username, Message.new(:start_fail, {:reason => :already_started}))
            false
        elsif @game_state == :genesis
            send_to_user(username, Message.new(:start_fail, {:reason => :world_not_generated}))
            false
        elsif @game_state == :generating
            send_to_user(username, Message.new(:start_fail, {:reason => :world_generation_in_progress}))
            false
        end
    end

    def perform_command(username, params)
        begin
            data = case params[:command]
            when :spawn,:summon
                raise(InvalidCommandError, "Permission denied") unless is_admin?(username)
                raise(InvalidCommandError, "#{params[:command].title} what?") unless params[:target]
                creator  = @game_core.get_character(username)
                position = creator.absolute_position
                if params[:command] == :spawn
                    @game_core.create(params[:target], {:position => position})
                elsif params[:command] == :summon
                    @game_core.create_npc(params[:target], {:position => position})
                end
                "#{params[:command].title}ing a #{params[:target]}"
            when :help
                params[:target] ||= @game_core.db.static_types_of(:command)
                Words.describe_help(params)
            when :stats
                character = @game_core.get_character(username)
                raise(StateError, "User #{username} has no character") unless character
                raise(InvalidCommandError, "Character #{character.monicker} has no stats") unless character.uses?(HasAspects)
                params[:agent] = character
                # FIXME - Allow users to request a specific subset of stats
                params[:target] = [character.attributes.values, character.attributes.values]
                Words.describe_stats(params)
            else
                raise(ArgumentError, "Unrecognized command '#{params[:command]}'")
            end
            send_to_user(username, Message.new(:command_reply, :text => data))
        rescue Exception => e
            Log.debug(["Failed to perform user command", e.message, e.backtrace])
            send_to_user(username, Message.new(:command_reply, :text => e.message))
        end
    end

    def perform_action(username, params, allow_clarification=true)
        command = params[:command]

        begin
            Log.debug("Performing command #{command}", 8)
            @game_core.protect do
                character = @game_core.get_character(username)
                params = Commands.stage(@game_core, command, params.merge(:agent => character))
            end
        rescue Exception => e
            Log.debug(["Failed to stage command #{command}", e.message, e.backtrace])
            if AmbiguousCommandError === e && allow_clarification
                send_to_user(username, Message.new(:act_clarify, {:verb => e.verb, :missing_params => e.missing_params}))
            else
                send_to_user(username, Message.new(:act_fail, {:reason => e.message}))
            end
            return
        end

        begin
            @game_core.protect do
                Commands.do(@game_core, command, params)
            end
            send_to_user(username, Message.new(:act_success, {:description => params}))
        rescue Exception => e
            Log.error(["Failed to perform command #{command}", e.message, e.backtrace])
            send_to_user(username, Message.new(:act_fail, {:reason => e.message}))
        end
    end

    def process_message(message, username=nil)
        case message.message_class
        when :lobby;        process_lobby_message(message, username)
        when :game;         process_game_message(message, username)
        when :core, :tick;  process_core_message(message)
        else 
            Log.error("Lobby doesn't know how to handle message class #{message.message_class}")
        end
    end

    def process_core_message(message)
        case message.type
        when :tick
            Log.debug("Lobby tick", 6)
        when :unit_killed,:object_destroyed
            @users.keys.each do |username|
                # Core messages already protected (issued by a protected method)
                character = @game_core.get_character(username)
                next if character.nil?
                next unless message.location == character.absolute_position

                if message.target == character
                    Log.info("Character #{character.monicker} dies!")
                    @game_core.remove_character(username, true)
                    broadcast(Message.new(:user_dies, {:result => username}))
                end
            end
        end
    end

    def process_game_message(message, username)
        unless is_playing?(username)
            Log.error("Can't parse game message for #{username} - user isn't playing yet")
        end

        case message.type
        when :clarification
            Log.error("FIXME")
            # Just assume an affirmative response with no clarification and proceed
            perform_action(username, @users[username][:last_action_params], false)
        when :command
            params = Words.decompose_command(message.text)
            perform_command(username, params)
        when :act
            Log.debug("Parsing action message", 8)
            params = Words.decompose_command(message.command)

            @users[username][:last_action_params] = params.dup
            perform_action(username, params)
        else
            Log.warning("Unhandled game message type #{message.type} received from client")
        end
    end

    def process_lobby_message(message, username)
        case message.type
        when :get_game_params
            # Eventually there will actually *be* game params, at which point we'll want to send them here
            Log.warning("PARTIALLY IMPLEMENTED")
            send_to_user(username, Message.new(:game_params, {:params=>{}}))
        when :generate_game
            generate_game(username)
        when :set_character_opt
            @users[username][:character_options] ||= {}
            @users[username][:character_options][message.property] = message.value
            Log.debug("Character property #{message.property} set to #{message.value}")
            send_to_user(username, Message.new(:opt_set_ok))
        when :get_character_opts
            begin
                raise "You must create a game before fetching character options" unless @game_core

                # This is a query for a list of character options
                opts = case message.property
                when :morphism
                    archetype = @users[username][:character_options][:archetype]
                    raise(MissingProperty, "Character archetype must be set before morphism can be selected") unless archetype

                    morphic_choices = []
                    morphic_parts   = @game_core.db.info_for(archetype, :morphic)
                    morphic_parts.each do |morphic_part|
                        morphic_choices.concat(morphic_part[:morphism_classes])
                    end
                    morphic_choices.uniq
                when :archetype
                    @game_core.db.instantiable_types_of(:civil)
                else
                    raise(NotImplementedError, "Unknown character options property #{message.property.inspect}")
                end
                send_to_user(username, Message.new(:character_opts, {:options => opts}))
            rescue Exception => e
                send_to_user(username, Message.new(:opts_unavailable, {:reason => e.message}))
            end
        when :create_character
            # Basically, this is the event that triggers the character to be saved and used
            # The server isn't involved in the character creation dialog at all, only the committing of that data
            begin
                raise "You must create a game before creating a character" unless @game_core
                # TODO - Add a check for a character with the same name
                Log.info("Creating character for #{username}")
                @game_core.create_character(self, username, @users[username][:character_options])
                Log.info("Character created")
                send_to_user(username, Message.new(:character_ready))
                if @game_state == :playing
                    send_to_user(username, Message.new(:begin_playing))
                end
            rescue Exception => e
                Log.error([e.message, e.backtrace])
                send_to_user(username, Message.new(:character_not_ready, {:reason => e.message}))
            end
        when :list_characters
            if @game_state == :genesis
                send_to_user(username, Message.new(:no_characters, {:reason => "Game not yet generated"}))
            else
                characters = get_user_characters(username)
                if characters.empty?
                    send_to_user(username, Message.new(:no_characters, {:reason => "None found"}))
                else
                    send_to_user(username, Message.new(:character_list, {:characters => characters}))
                end
            end
        when :select_character
            set_user_character(username, message.character_name)
        when :start_game
            start_game(username)
        when :toggle_pause
            Log.warning("UNIMPLEMENTED")
        else
            Log.error("Unhandled lobby message type #{message.type} received from client")
        end
    end
end
