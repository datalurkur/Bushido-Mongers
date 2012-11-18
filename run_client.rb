#!/usr/bin/ruby

require 'net/remote_client'

# DEBUG
config = {
    :username => "test_user",
    :password => "test_password",
    :lobby_name => "test_lobby",
    :lobby_password => "test_lobby_password",
    :server_menu_autocmd => :create_lobby
}

Log.setup
c = RemoteClient.new("localhost",RemoteClient::DEFAULT_LISTEN_PORT,config)
