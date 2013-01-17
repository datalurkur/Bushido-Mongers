require './net/lobby'

class WebEnabledLobby < Lobby
    def initialize(name, password_hash, creator, web_server, &block)
        super(name, password_hash, creator, &block)

        @web_server = web_server
        setup_web_routes
    end

    def web_uri;       "/#{@name.escape}";                        end
    def web_directory; "#{@web_server.web_root}/#{@name.escape}"; end

    def characters_uri;          "#{web_uri}/characters";                    end
    def characters_directory;    "#{web_directory}/characters";              end
    def uri_for(username);       "#{web_uri}/characters/#{username.escape}"; end
    def directory_for(username)
        dir = "#{web_directory}/characters/#{username.escape}"
        ensure_directory_exists(dir)
        dir
    end

    def ensure_directory_exists(directory)
        Dir.mkdir(directory) unless File.exist?(directory)
    end

    def create_lobby_map
        map_name     = "map.png"
        map_location = File.join(web_directory, map_name)
        map_uri      = File.join(web_uri, map_name)
        map_data     = @game_core.world.get_map
        f = File.open(map_location, 'w')
        f.write(map_data)
        f.close
    end

    def create_map_for(username)
        character = @game_core.get_character(username)

        map_name     = "map.png"
        map_location = File.join(directory_for(username), map_name)
        map_uri      = File.join(uri_for(username), map_name)
        map_data     = @game_core.world.get_map({character.absolute_position => :red})
        f = File.open(map_location, 'w')
        f.write(map_data)
        f.close
    end

    def setup_web_routes
        [web_directory, characters_directory].each { |dir| ensure_directory_exists(dir) }

        # The lobby landing page
        @web_server.add_route(/#{web_uri}$/i) do |args|
            @web_server.process_template("lobby.haml", binding, args)
        end

        # Lobby map
        @web_server.add_route(/#{web_uri}\/map\.png/i) do |args|
            create_lobby_map
            @web_server.find_file(File.join(web_uri, "map.png"))
        end

        # User pages
        @web_server.add_route(/#{characters_uri}\/#{@web_server.wildcard}$/i) do |args|
            username = args[0].unescape
            return nil unless @users.has_key?(username)
            @web_server.process_template("character.haml", binding, args)
        end

        # Maps within user directories
        @web_server.add_route(/#{characters_uri}\/#{@web_server.wildcard}\/map\.png/i) do |args|
            username = args[0].unescape
            return nil unless @users.has_key?(username)
            create_map_for(username)
            @web_server.find_file(File.join(uri_for(username), "map.png"))
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
