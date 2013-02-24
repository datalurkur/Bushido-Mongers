require './util/log'

=begin
    NECESSARY ENHANCEMENTS
    ======================
    1) There needs to be some discussion about character portability between worlds.
    We should allow this, but we need to think about things like character location between worlds.
        - If a character saves and reloads a character in the same world, he should be at the same location
        - If a character saves and reloads a character between worlds, his old position doesn't make sense for the new world
    This means we need a way to identify which world a character was saved in (or store character position within the world, that might make more sense)
    This means we also need a way to identify worlds uniquely (I suggest hashing the name of the world with a timestamp)
=end

module Character
    class << self
        CHARACTER_DIRECTORY = "./data/characters"

        # It would be cleaner to store the timestamp in the character object, but doing that doesn't allow us to check for the existence of a (possibly) corrupt character
        # Basically if we store all the character information inside the object and use a random hash as the filename, we lose the ability to pull out metadata about a corrupt character
        # It just turns into a random hash that we know nothing about
        def to_filename(name)
            name.gsub(/ /, '_') + "_" + Time.now.to_i.to_s
        end

        def parse_filename(name)
            parts          = name.split(/_/)
            character_name = parts[0...-1].join(' ')
            timestamp      = parts.last
            [character_name, timestamp]
        end

        def get_user_directory(username)
            user_directory = File.join(CHARACTER_DIRECTORY, username)

            # Create the user directory if it doesn't exist (new user)
            Dir.mkdir(user_directory) unless File.exists?(user_directory)

            user_directory
        end

        # Since users will only ever be operating on a single thread, we don't have to care about concurrent disk IO screwing things up
        def user_directory_contents(username)
            udir = get_user_directory(username)

            # Get a list of all versions of all characters for this user
            saves = Dir.entries(udir).reject { |filename| filename == "." || filename == ".." }

            # Parse the character meta-data from the saves
            saves.collect do |filename|
                character_name, timestamp = parse_filename(filename)

                {
                    :filename       => filename,
                    :character_name => character_name,
                    :timestamp      => timestamp,
                }
            end
        end

        def save(username, character)
            # Clean up instance-specific data
            character.nil_position
            character.nil_core

            filename = to_filename(character.name)
            full_filename = File.join(get_user_directory(username), filename)
            f = File.open(full_filename, 'w')
            f.write(Marshal.dump(character))
            f.close
        end

        def attempt_to_load(username, character_name)
            unless get_characters_for(username).include?(character_name)
                Log.debug("No character #{character_name} found")
                return [nil, []]
            else
                history        = get_history(username, character_name)
                failed_choices = []
                character      = nil
                history.each do |cdata|
                    begin
                        character = Character.load_file(username, cdata[:filename])
                        break
                    rescue Exception => e
                        # This one failed to load, try the next one
                        Log.debug(["Failed to load character with timestamp #{cdata[:timestamp]}", e.message])
                        failed_choices << cdata
                    end
                end
                return [character, failed_choices]
            end
        end

        def load_file(username, filename)
            Marshal.load(File.read(File.join(get_user_directory(username), filename)))
        end

        def get_characters_for(username)
            user_directory_contents(username).collect do |fdata|
                fdata[:character_name]
            end.uniq.compact
        end

        def get_history(username, character_name)
            contents = user_directory_contents(username)
            history  = contents.select { |fdata| fdata[:character_name] == character_name }
            history.sort { |x,y| x[:timestamp] <=> y[:timestamp] }
        end

        def at_message(instance, message)
            case message.type
            when :unit_moves
                if (message.unit != instance) && instance.witnesses?([message.start, message.finish])
                    instance.inform_user(message)
                end
            when :unit_attacks
                locations = [message.attacker.absolute_position, message.defender.absolute_position]
                # Make sure the user sees the attack if they're the target, even if the attacker is hidden
                if (message.attacker == instance) || (message.defender == instance) || instance.witnesses?(locations)
                    instance.inform_user(message)
                end
            when :unit_acts
                # TODO - Add in distance scoping for different actions (shouting can be witnessed from further away than talking)
                if (message.unit != instance) && instance.witnesses?([message.position])
                    instance.inform_user(message)
                end
            when :object_destroyed
                if instance.witnesses?([message.position])
                    instance.inform_user(message)
                end
            when :tick
            else
                Log.debug("Character received unhandled message of type #{message.type}")
            end
        end
    end

    def witnesses?(locations=[], scope=:immediate)
        # TODO - Use scope to determine if events in adjacent zones can be heard / seen
        # TODO - Add perception checks
        return locations.include?(absolute_position)
    end

    # Since this object is sometimes saved and loaded, we need to recreate it gracefully
    def set_core(core)
        @core = core
    end

    def nil_core
        @core = nil
    end

    def set_user_callback(lobby, username)
        Log.debug("Setting user callback for #{monicker}")
        @lobby    = lobby
        @username = username
    end

    def inform_user(message)
        unless @lobby
            Log.error(caller)
        end
        raise(StateError, "User callback not set for #{monicker}") unless @lobby
        event_properties = message.params.merge(:event_type => message.type)
        @lobby.send_to_user(@username, Message.new(:game_event, {:description => event_properties}))
    end

    def nil_user_callback
        Log.debug("Clearing user callback for #{monicker}")
        @lobby    = nil
        @username = nil
    end
end
