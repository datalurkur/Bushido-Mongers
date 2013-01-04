#!/usr/bin/ruby

require 'net/remote_client'

$config = {
    :server_ip => "localhost",
    :server_port => RemoteClient::DEFAULT_LISTEN_PORT,
    :lobby_name => "test_lobby",
    :lobby_password => "test_lobby_password",
    :server_menu_autocmd => :join_lobby
}

Log.setup("Main", "client")

$client = RemoteClient.new($config)

signals = ["TERM","INT"]
signals.each do |signal|
    Signal.trap(signal) {
        Log.debug("Caught signal #{signal}")
        $client.stop if $client
    }
end

$client.start
