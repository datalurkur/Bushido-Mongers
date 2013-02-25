require './bushido'
require './util/traps'

$config = {
    :server_hostname     => "localhost",
    :server_port         => DEFAULT_LISTEN_PORT,
}

Log.setup("Main", "client")

$client = RemoteClient.new($config)

trap_signals do
    $client.stop if $client
    exit
end

$client.start

while $client.running?
    sleep 10
end
