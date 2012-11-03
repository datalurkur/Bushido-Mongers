#!/usr/bin/ruby

require 'irc_server'

Signal.trap("TERM") do
    $server.stop if $server.running
end

# Parameters
servername = "irc.freenode.net"
port       = 7000
nick       = "ninja_game_bot"

# Construct the IRC object
$server = IRCServer.new
$server.start(servername,port,nick)

while($server.running) do
    begin
        # Get local user input
        input = gets
        case input
        when /stop/
            debug("Stopping server")
            $server.stop
        else
        end
    rescue Exception => e
        debug(["Failed to parse admin command",e.message,e.backtrace])
    end
end
