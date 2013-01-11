require './net/lobby'

class WebEnabledLobby < Lobby
    def initialize(name, password_hash, creator, web_server, &block)
        super(name, password_hash, creator, &block)

        @web_server = web_server
        setup_web_routes
    end

    def web_directory
        File.join(@web_server.web_root, @name.escape)
    end

    def web_uri
        "/" + @name.escape
    end

    def setup_web_routes
        Dir.mkdir(web_directory) unless File.exist?(web_directory)

        @web_server.add_route(/\/#{@name.escape}$/i) do |args|
            @web_server.process_template("lobby.erb", binding, args)
        end

        @web_server.add_route(/\/#{@name.escape}\/characters\/#{@web_server.wildcard}$/i) do |args|
            ["Status page for #{args.first} (in lobby #{@name})", "text/plain"]
        end

        @web_server.add_route(/\/#{@name.escape}\/#{@web_server.wildcard}$/i) do |args|
            @web_server.find_file(File.join(web_uri, args.first))
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
