require 'net/lobby'

class WebEnabledLobby < Lobby
    def initialize(name, password_hash, creator, web_server, &block)
        super(name, password_hash, creator, &block)

        @web_server = web_server
        setup_web_routes
    end

    def setup_web_routes
        @web_server.add_route(/\/#{@name.escape}$/i) do |args|
            @web_server.process_template("index.erb", binding, args)
        end

        @web_server.add_route(/\/#{@name.escape}\/#{@web_server.wildcard}/i) do |args|
            ["Status page for #{args.first} (in lobby #{@name})", "text/plain"]
        end
    end
end
