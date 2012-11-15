#!/usr/bin/ruby

require 'net/remote_client'

config = {
    :username => "datalurkur",
    :password => "herpderp",
    :lobby_name => "test_lobby",
    :lobby_password => "test",
    :server_menu_autocmd => :create_lobby
}

Log.setup
c = RemoteClient.new("localhost",RemoteClient::DEFAULT_LISTEN_PORT,config)
