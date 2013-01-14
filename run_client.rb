require './util/traps'
require './net/remote_client'

$config = {
    :server_hostname     => "localhost",
    :server_port         => DEFAULT_LISTEN_PORT,
    :lobby_name          => "test_lobby",
    :lobby_password      => "test_lobby_password",
    :server_menu_autocmd => :join_lobby
}

Log.setup("Main", "client")

$client = RemoteClient.new($config)

trap_signals do
    $client.stop if $client
    exit
end

$client.start

while true
    sleep 30
end
