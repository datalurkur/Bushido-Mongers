require './world/factories'
require './game/tables'
require './game/object_extensions'
require './raws/db'
require './message'

class GameCore
    attr_reader :world, :db

    def initialize
    end

    # TODO - Write save / load methods

    def setup(args)
        @tick_rate     = args[:tick_rate] || (30)
        @ticking       = false
        @ticking_mutex = Mutex.new

        # Read the raws
        raw_group = args[:raw_group] || "default"
        @db       = ObjectDB.get(raw_group)
        # And the word text information.
        @words_db = WordParser.load
        # And finally read in some basic noun & adjective information from the raws db.
        WordParser.read_raws(@words_db, @db)

        setup_world(args.merge(:core => self))
    end

    def teardown
        teardown_world
        @db            = nil
        @words_db      = nil
        @ticking       = false
        @ticking_mutex = nil
    end

    def setup_world(args)
        Log.debug("Creating world")
        @world = WorldFactory.generate(args)

        Log.debug("Populating world with NPCs and items")
        @world.populate(self)
    end

    def teardown_world
        @world = nil
    end

    # TICK MAINTENANCE
    def start_ticking
        already_ticking = false
        @ticking_mutex.synchronize {
            already_ticking = @ticking
            @ticking = true
        }
        raise "Already ticking" if already_ticking
        Thread.new do
            Log.name_thread("Tick")
            begin
                keep_ticking = true
                while keep_ticking
                    @ticking_mutex.synchronize {
                        dispatch_ticks
                        keep_ticking = @ticking
                    }
                    sleep(@tick_rate)
                end
            rescue Exception => e
                Log.debug(["Terminating abnormally", e.message, e.backtrace])
            end
            Log.debug("Ticking halted")
        end
    end
    def stop_ticking
        @ticking_mutex.synchronize {
            @ticking = false
        }
    end
    def dispatch_ticks
        Message.dispatch(self, :tick)
    end

    # CHARACTER MAINTENANCE
    def characters;       @characters       ||= {}; end
    def cached_positions; @cached_positions ||= {}; end
    def load_character(username, character_name)
        cached_positions[username]

        character, failures = Character.attempt_to_load(username, character_name)
        if character
            character.set_position(cached_positions[username] || @world.random_starting_location)
            character.set_core(self)
            characters[username] = character
            Log.info("Character #{character.name} loaded for #{username}")
            Message.register_listener(self, :core, character)
        end

        return [character, failures]
    end
    def create_character(username, details)
        begin
            position  = @world.random_starting_location
            character = @db.create(self, :character, details.merge(:position => position))

            characters[username] = character
            Log.info("Character #{character.name} created for #{username}")
            Message.register_listener(self, :core, character)

            return true
        rescue Exception => e
            Log.debug(["Failed to create new character", e.message, e.backtrace])
            return false
        end
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
        characters.each do |k,v|
            return k if v == character
        end
        return nil
    end
    def remove_character(username, character_dies=false)
        character = characters[username]

        Message.unregister_listener(self, :core, character)

        if character_dies
            cached_positions[username] = nil
            # TODO - We should determine what happens when a character is killed - can he reload his last save, or must he start a new character?
        else
            # Cache the character's position within the game server so that it can be placed back where it exited when logging back in
            cached_positions[username] = character.position
            Character.save(username, character)
        end
        characters.delete(username)
    end
end
