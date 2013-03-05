require './world/factories'
require './game/tables'
require './game/object_extensions'
require './raws/db'
require './util/exceptions'

class GameCore
    attr_reader :world, :db

    def initialize
        Message.setup(self)

        @usage_mutex = Mutex.new
    end

    # TODO - Write save / load methods

    # PUBLIC (THREADSAFE) METHODS
    def setup(args)
        @usage_mutex.synchronize do
            Log.info("Setting up game core")

            @tick_rate     = args[:tick_rate] || (30)
            @ticking       = false

            # Read the raws
            raw_group = args[:raw_group] || "default"
            @db       = ObjectDB.get(raw_group)
            # And the word text information.
            @words_db = WordParser.load
            # And finally read in some basic noun & adjective information from the raws db.
            WordParser.read_raws(@words_db, @db)

            setup_world(args)
            @awaiting_destruction = []

            @setup = true
        end
    end

    def teardown
        @usage_mutex.synchronize do
            teardown_world
            @db            = nil
            @words_db      = nil
            @ticking       = false

            @setup = false
        end
    end

    def setup?
        ret = nil
        @usage_mutex.synchronize do
            ret = @setup
        end
        ret
    end

    def create(type, hash = {})
        @db.create(self, type, hash)
    end

    def flag_for_destruction(object, destroyer)
        @awaiting_destruction << [object, destroyer]
    end

    def destroy_flagged
        @awaiting_destruction.each do |object, destroyer|
            object.destroy(destroyer)
        end
        @awaiting_destruction.clear
    end

    # TICK MAINTENANCE
    def start_ticking
        already_ticking = false
        @usage_mutex.synchronize do
            already_ticking = @ticking
            @ticking = true
        end

        raise(StateError, "Already ticking.") if already_ticking

        Thread.new do
            Log.name_thread("Tick")
            begin
                keep_ticking = true
                while keep_ticking
                    sleep(@tick_rate)
                    @usage_mutex.synchronize do
                        dispatch_ticks
                        keep_ticking = @ticking
                    end
                end
            rescue Exception => e
                Log.debug(["Terminating abnormally", e.message, e.backtrace])
            end
            Log.debug("Ticking halted")
        end
    end

    def stop_ticking
        @usage_mutex.synchronize do
            @ticking = false
        end
    end

    def protect(&block)
        @usage_mutex.synchronize do
            yield
        end
    end

    # CHARACTER MAINTENANCE
    def load_character(lobby, username, character_name)
        ret = nil
        @usage_mutex.synchronize do
            cached_positions[username]

            character, failures = Character.attempt_to_load(username, character_name)
            if character
                character.set_core(self)
                character.set_position(cached_positions[username] || @world.random_starting_location)
                characters[username] = character
                Log.info("Character #{character.name} loaded for #{username}")
                Message.register_listener(self, :core, character)
                character.set_user_callback(lobby, username)
            end

            ret = [character, failures]
        end
        return ret
    end
    def create_character(lobby, username, details)
        ret = nil
        @usage_mutex.synchronize do
            position  = @world.random_starting_location
            character = @db.create(self, :character, details.merge(:position => position))

            characters[username] = character
            Log.info("Character #{character.name} created for #{username}")
            Message.register_listener(self, :core, character)
            character.set_user_callback(lobby, username)

            ret = character
        end
        return ret
    end
    def get_user_characters(username)
        Character.get_characters_for(username)
    end
    def has_active_character?(username)
        characters.has_key?(username)
    end
    def get_character(username)
        characters[username]
    end
    def get_character_user(character)
        ret = nil
        characters.each do |k,v|
            if v == character
                ret = k
                break
            end
        end
        return ret
    end
    def remove_character(username, character_dies=false)
        character = characters[username]

        Message.unregister_listener(self, :core, character)
        character.nil_user_callback

        if character_dies
            cached_positions[username] = nil
            # TODO - We should determine what happens when a character is killed - can he reload his last save, or must he start a new character?
        else
            # Cache the character's position within the game server so that it can be placed back where it exited when logging back in
            cached_positions[username] = character.absolute_position
            Character.save(username, character)
            character.destroy(nil, true)
        end
        characters.delete(username)
    end

    # PRIVATE (NOT THREADSAFE) METHODS
    private
    def setup_world(args)
        Log.debug("Creating world")
        @world = WorldFactory.generate(self, args)

        Log.debug("Populating world with NPCs and items")
        @world.populate
    end

    def teardown_world
        @world = nil
    end

    def dispatch_ticks
        Message.dispatch(self, :tick)
    end

    def characters;       @characters       ||= {}; end
    def cached_positions; @cached_positions ||= {}; end
end
