require './net/lobby'
require './net/web_renderer'

class WebEnabledLobby < Lobby
    include WebRenderer

    def initialize(name, password_hash, creator, web_server, &block)
        super(name, password_hash, creator, &block)

        @web_server = web_server
        setup_web_routes
    end

    def web_root;                   @web_server.web_root;                       end
    def web_uri;                    "/#{@name.escape}";                         end
    def web_directory;              "#{web_root}/#{@name.escape}";              end
    def map_uri;                    "#{web_uri}/map.png";                       end
    def map_location;               "#{web_directory}/map.png";                 end
    def characters_uri;             "#{web_uri}/characters";                    end
    def characters_directory;       "#{web_directory}/characters";              end
    def uri_for(username);          "#{characters_uri}/#{username.escape}";     end
    def map_uri_for(username);      "#{uri_for(username)}/map.png";             end
    def map_location_for(username); "#{directory_for(username)}/map.png";       end

    def directory_for(username)
        ensure_directory_exists("#{characters_directory}/#{username.escape}")
    end

    def ensure_directory_exists(directory)
        Dir.mkdir(directory) unless File.exist?(directory)
        directory
    end

    def create_lobby_map
        map_data = @game_core.world.get_map
        f = File.open(map_location, 'w')
        f.write(map_data)
        f.close
    end

    def create_map_for(username)
        character = @game_core.get_character(username)
        map_data  = @game_core.world.get_map({character.absolute_position => :red})
        f = File.open(map_location_for(username), 'w')
        f.write(map_data)
        f.close
    end

    def setup_web_routes
        [web_directory, characters_directory].each { |dir| ensure_directory_exists(dir) }

        # The lobby landing page
        @web_server.add_route(/#{web_uri}$/i) do |args|
            get_template(File.join(web_root, "lobby.haml"), {:lobby => self})
        end

        # Lobby map
        @web_server.add_route(/#{map_uri}$/i) do |args|
            create_lobby_map
            get_file(map_location)
        end

        # User pages
        @web_server.add_route(/#{characters_uri}\/#{wildcard}$/i) do |args|
            username = args[0].unescape
            return nil unless @users.has_key?(username)
            get_template(File.join(web_root, "character.haml"), {
                :lobby     => self,
                :username  => username,
                :character => @game_core.get_character(username)
            })
        end

        # Maps within user directories
        @web_server.add_route(/#{characters_uri}\/#{wildcard}\/map\.png/i) do |args|
            username = args[0].unescape
            return nil unless @users.has_key?(username)
            create_map_for(username)
            get_file(map_location_for(username))
        end
    end

    def process_game_message(message, username)
        if message.type == :get_link
            send_to_user(username, Message.new(:link, {:uri => web_uri}))
        else
            super(message, username)
        end
    end
end
