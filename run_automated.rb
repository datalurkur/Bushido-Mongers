require './util/traps'
require './net/automated_client'

$config = {
    :server_hostname => "localhost",
    :server_port     => PairedAutoClient::DEFAULT_LISTEN_PORT,
    :username        => "zphobic",
    :password        => "d3rt3rl3rk3r",
    :lobby_name      => "test_lobby",
    :lobby_password  => "test",
}

Log.setup("Main", "client")
$client = PairedAutoClient.new($config)

trap_signals do
    $client.stop if $client
end

$client.push_pair({:type => :choose_from_list,  :field => :server_menu_choice, :choices => [:list_lobbies, :join_lobby, :create_lobby, :disconnect]},
                  {:type => :valid_input,       :input => :join_lobby})
$client.push_pair({:type => :text_field,        :field => :lobby_name},
                  {:type => :valid_input,       :input => $config[:lobby_name]})
$client.push_pair({:type => :text_field,        :field => :lobby_password},
                  {:type => :valid_input,       :input => $config[:lobby_password]})

$client.start
