require 'util/log'

=begin
    NECESSARY ENHANCEMENTS
    ======================
    1) There needs to be some discussion about character portability between worlds.
    We should allow this, but we need to think about things like player location between worlds.
        - If a player saves and reloads a character in the same world, he should be at the same location
        - If a player saves and reloads a character between worlds, his old position doesn't make sense for the new world
    This means we need a way to identify which world a player was saved in (or store player position within the world, that might make more sense)
    This means we also need a way to identify worlds uniquely (I suggest hashing the name of the world with a timestamp)
=end

class Player
    class << self
        CHARACTER_DIRECTORY = "data/characters"

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

        def save_character(username, character)
            filename = to_filename(character.name)
            full_filename = File.join(get_user_directory(username), filename)
            f = File.open(full_filename, 'w')
            f.write(Marshal.dump(character))
            f.close
        end

        def load_character(username, filename)
            Marshal.load(File.read(File.join(get_user_directory(username), filename)))
        end

        def get_characters_for(username)
            user_directory_contents(username).collect do |fdata|
                fdata[:character_name]
            end.uniq.compact
        end

        def get_character_history(username, character_name)
            contents = user_directory_contents(username)
            history  = contents.select { |fdata| fdata[:character_name] == character_name }
            history.sort { |x,y| x[:timestamp] <=> y[:timestamp] }
        end
    end

    attr_reader :name
    def initialize(name)
        @name = name
    end
end
