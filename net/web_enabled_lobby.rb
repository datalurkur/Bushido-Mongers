require './net/lobby'

class WebEnabledLobby < Lobby
    def initialize(name, password_hash, creator, web_server, &block)
        super(name, password_hash, creator, &block)

        @web_server = web_server
        setup_web_routes
    end

    def web_uri;       "/#{@name.escape}";                        end
    def web_directory; "#{@web_server.web_root}/#{@name.escape}"; end

    def characters_directory;    "#{web_directory}/characters";                    end
    def uri_for(username);       "#{web_uri}/characters/#{username.escape}";       end
    def directory_for(username)
        dir = "#{web_directory}/characters/#{username.escape}"
        ensure_directory_exists(dir)
        dir
    end

    def ensure_directory_exists(directory)
        Dir.mkdir(directory) unless File.exist?(directory)
    end

    def setup_web_routes
        [web_directory, characters_directory].each { |dir| ensure_directory_exists(dir) }

        # The lobby landing page
        @web_server.add_route(/\/#{@name.escape}$/i) do |args|
            @web_server.process_template("lobby.erb", binding, args)
        end

        # Files within the lobby directory
        @web_server.add_route(/\/#{@name.escape}\/#{@web_server.wildcard}$/i) do |args|
            @web_server.find_file(File.join(web_uri, args.first.unescape))
        end

        # User pages
        @web_server.add_route(/\/#{@name.escape}\/characters\/#{@web_server.wildcard}$/i) do |args|
            username = args[0].unescape
            return nil unless @users.has_key?(username)
            @web_server.process_template("character.erb", binding, args)
        end

        # Files within user directories
        @web_server.add_route(/\/#{@name.escape}\/characters\/#{@web_server.wildcard}\/#{@web_server.wildcard}$/i) do |args|
            username = args[0].unescape
            return nil unless @users.has_key?(username)
            @web_server.find_file(File.join(uri_for(username), args[1].unescape))
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
