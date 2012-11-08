#!/usr/bin/ruby

require 'remote_client'

Log.setup
c = RemoteClient.new("localhost",RemoteClient::DEFAULT_LISTEN_PORT)
