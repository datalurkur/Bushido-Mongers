#!/usr/bin/ruby

require 'remote_client'

config = {
    :username => "datalurkur",
    :password => "herpderp",
}

Log.setup
c = RemoteClient.new("localhost",RemoteClient::DEFAULT_LISTEN_PORT,config)
