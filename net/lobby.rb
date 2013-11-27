require './game/cores/default'
require './game/descriptors'
require './game/core_loader'
require './http/http_server'
require './net/manifests'

# Lobbies group players together with a Game and facilitate communications between the game and the client sockets
class Lobby
    include GameCoreLoader

    attr_reader :name, :game_state, :game_core

    def initialize(name, password_hash, creator, &block)
        # Credentials
        @name              = name
        @password_hash     = password_hash

        # Game administration / socket maintenance / broadcast list
        @users             = {}
        @dialects          = {}

        @users[creator]    = {:admin => true}
        @game_creator      = creator
        @default_admin     = creator

        # Local state, basically
        @game_state        = :no_core

        # Game objects
        @game_core         = nil
        @game_args         = {}

        # How the lobby sends messages back to clients (while still using the thread-safe mutexes and methods)
        raise(ArgumentError, "No send callback passed to lobby (block required).") unless block_given?
        @send_callback     = block
    end

    def is_admin?(username);   @users[username][:admin];                            end
    def is_playing?(username); @game_core && @game_core.active_character(username); end
    def user_list;             @users.keys.select { |user| is_playing?(user) };     end

    def check_permissions(command, username)
        # Later on this will be more interesting, but now just allows admins to do interesting stuff
        case command
        when :generate_world,:save_world,:load_world,:start_game
            return is_admin?(username)
        else
            return true
        end
    end

    def get_user_dialect(username); @dialects[username] || :text; end

    def send_to_user(username, message)
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

    def add_user(username)
        if @users[username]
            Log.debug("#{username} is already active in the lobby")
            return
        end

        Log.info("#{username} added to #{name}")
        broadcast(Message.new(:user_joins, {:result => username}), [username])
        @users[username]    = {}
        @dialects[username] = :text

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
            @game_core.extract_character(username)
        end
        @users.delete(username)
        @dialects.delete(username)
        Log.info("#{username} was removed from #{name}")
        broadcast(Message.new(:user_leaves, {:result => username}))
    end

    def get_user_characters(username); @game_core.get_characters_for(username); end

    def set_user_character(username, character_uid)
        if @game_state == :no_core
            send_to_user(username, Message.new(:character_not_ready, {:reason => "Game has not been generated"}))
            return
        end

        if is_playing?(username)
            send_to_user(username, Message.new(:character_not_ready, {:reason => "Character already loaded"}))
            return
        end

        @game_core.inject_character(username, character_uid)
        send_to_user(username, Message.new(:character_ready))
        if @game_state == :playing
            send_to_user(username, Message.new(:begin_playing))
        end
    end

    def get_core_state
        if @game_state == :no_core
            return nil
        elsif @game_state == :pending
            return :core_pending
        elsif @game_state == :playing || @game_state == :ready
            return :core_exists
        else
            return :unknown
        end
    end

    def set_core(core)
        @game_state = :pending
        @game_core  = core
        Message.register_listener(@game_core, :core, self)
        Message.register_listener(@game_core, :tick, self)
        @game_core.set_lobby(self)
    end

    def save_world(username)
        send_to_user(username, Message.new(:save_pending))
        extra_info = {
            :name       => @name,
            :creator    => @game_creator,
            :created_on => @game_core.created_on,
            :saved_on   => Time.now
        }
        save_core(@game_core, extra_info)
        broadcast(Message.new(:save_success))
    end

    def start_game(username)
        if @game_state == :ready
            @game_state = :playing

            Log.info("Game started")
            broadcast(Message.new(:start_success))

            @users.keys.each do |username|
                if @game_core.active_character(username)
                    send_to_user(username, Message.new(:begin_playing))
                end
            end

            @game_core.start_ticking
        elsif @game_state == :playing
            send_to_user(username, Message.new(:start_fail, {:reason => :already_started}))
            false
        elsif @game_state == :no_core
            send_to_user(username, Message.new(:start_fail, {:reason => :world_not_generated}))
            false
        elsif @game_state == :pending
            send_to_user(username, Message.new(:start_fail, {:reason => :world_generation_in_progress}))
            false
        end
    end

    def perform_command(username, params)
        begin
            data = case params[:command]
            when :save
                raise(InvalidCommandError, "Permission denied") unless is_admin?(username)
                save_world(username)
                nil
            when :spawn,:summon
                raise(InvalidCommandError, "Permission denied") unless is_admin?(username)
                raise(InvalidCommandError, "#{params[:command].title} what?") unless params[:target]
                raise(InvalidCommandError, "No character active - where to spawn?") unless @game_core.active_character(username)
                creator  = @game_core.get_character(username)
                position = creator.absolute_position
                if params[:command] == :spawn
                    @game_core.create(params[:target], {:position => position, :randomize => true, :creator => creator})
                elsif params[:command] == :summon
                    @game_core.create_npc(params[:target], {:position => position})
                end
                "#{params[:command].title}ing a #{params[:target]}"
            when :help
                params[:list] ||= @game_core.db.static_types_of(:command)
                @game_core.words_db.describe_list(params)
            when :stats
                raise(StateError, "User #{username} has no character") unless @game_core.active_character(username)
                character = @game_core.get_character(username)
                raise(InvalidCommandError, "Character #{character.monicker} has no stats") unless character.uses?(HasAspects)
                params[:agent] = character
                # FIXME - Allow users to request a specific subset of stats
                params[:list] = character.all_aspects
                @game_core.words_db.describe_list(params)
            else
                raise(ArgumentError, "Unrecognized command '#{params[:command]}'")
            end
            send_to_user(username, Message.new(:command_reply, :text => data)) if data
        rescue Exception => e
            Log.debug(["Failed to perform user command", e.message, e.backtrace])
            send_to_user(username, Message.new(:command_reply, :text => e.message))
        end
    end

    def perform_action(username, params, allow_clarification=true)
        begin
            Log.debug("Performing command #{params[:command]}", 8)
            @game_core.protect do
                raise(InvalidCommandError, "No character active!") unless @game_core.active_character(username)
                character = @game_core.get_character(username)
                params = Commands.stage(@game_core, params.merge(:agent => character))
            end
        rescue Exception => e
            Log.debug(["Failed to stage command #{params[:command]}", e.message, e.backtrace])
            if AmbiguousCommandError === e && allow_clarification
                send_to_user(username, Message.new(:act_clarify, {:verb => e.verb, :missing_params => e.missing_params}))
            else
                send_to_user(username, Message.new(:act_fail, {:reason => e.message}))
            end
            return
        end

        @game_core.send_with_dialect(username, :act_staged, params)

        begin
            @game_core.protect do
                Commands.do(@game_core, params)
            end
        rescue Exception => e
            Log.error(["Failed to perform command #{params[:command]}", e.message, e.backtrace])
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
        end
    end

    def process_game_message(message, username)
        unless is_playing?(username)
            Log.error("Can't parse game message for #{username} - user isn't playing yet")
        end

        case message.type
        when :clarification
            # Just assume an affirmative response with no clarification and proceed
            last_command = @users[username][:last_action_params][:command]
            reconstructed_phrase = "#{last_command} #{message.missing_param}"
            reconstructed_params = @game_core.words_db.decompose_command(reconstructed_phrase)

            new_params = @users[username][:last_action_params].merge(reconstructed_params)
            perform_action(username, new_params, false)
        when :command
            params = @game_core.words_db.decompose_command(message.text)
            perform_command(username, params)
        when :act
            Log.debug("Parsing action message", 8)
            params = @game_core.words_db.decompose_command(message.command)

            @users[username][:last_action_params] = params.dup
            perform_action(username, params)
        else
            Log.warning("Unhandled game message type #{message.type} received from client")
        end
    end

    def process_lobby_message(message, username)
        unless check_permissions(message, username)
            send_to_user(username, Message.new(:access_denied))
        end

        case message.type
        when :set_dialect
            @dialects[username] = message.dialect
        when :get_saved_worlds
            raw_infos = get_saved_cores_info
            info_to_client = {}
            raw_infos.each { |uid, info| info_to_client[uid] = SaveGameInfo.new(info) }
            send_to_user(username, Message.new(:saved_worlds_info, {:info_hash => info_to_client}))
        when :load_world
            core_state = get_core_state
            if core_state
                send_to_user(username, Message.new(:load_failed, {:reason => core_state}))
            else
                @game_state      = :pending
                send_to_user(username, Message.new(:load_pending))
                core, extra_info = load_core(message.uid)
                set_core(core)
                @game_creator    = extra_info[:creator]
                @game_state      = :ready
                broadcast(Message.new(:load_success))
            end
        when :save_world
            save_world(username)
        when :get_game_params
            # Eventually there will actually *be* game params, at which point we'll want to send them here
            Log.warning("PARTIALLY IMPLEMENTED")
            send_to_user(username, Message.new(:game_params, {:params=>@game_args}))
        when :generate_game
            core_state = get_core_state
            if core_state
                send_to_user(username, Message.new(:generation_fail, {:reason => core_state}))
            else
                @game_state = :pending
                send_to_user(username, Message.new(:generation_pending))
                core = DefaultCore.new
                core.setup(@game_args)
                set_core(core)
                @game_state = :ready
                broadcast(Message.new(:generation_success))
            end
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
                Log.info("Creating character for #{username}")
                @game_core.create_character(username, @users[username][:character_options])
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
            if @game_state == :no_core
                send_to_user(username, Message.new(:no_characters, {:reason => "Game not yet generated"}))
            else
                info_hash = @game_core.get_characters_for(username)
                if info_hash.empty?
                    send_to_user(username, Message.new(:no_characters, {:reason => "None found"}))
                else
                    send_to_user(username, Message.new(:character_list, {:info_hash => info_hash}))
                end
            end
        when :select_character
            set_user_character(username, message.character_uid)
        when :start_game
            start_game(username)
        when :toggle_pause
            Log.warning("UNIMPLEMENTED")
        else
            Log.error("Unhandled lobby message type #{message.type} received from client")
        end
    end
end
