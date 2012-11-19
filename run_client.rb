#!/usr/bin/ruby

require 'net/remote_client'

# DEBUG
config = {
    :server_ip => "localhost",
    :server_port => RemoteClient::DEFAULT_LISTEN_PORT,
    :username => "test_user",
    :password => "test_password",
    :lobby_name => "test_lobby",
    :lobby_password => "test_lobby_password",
    :server_menu_autocmd => :create_lobby
}

Log.setup("Main Thread", "client")
c = RemoteClient.new(config)
