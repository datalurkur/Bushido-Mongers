require './bushido'
require './util/traps'
require './util/cfg_reader'

config = CFGReader.read("test")
$client_config = {
    :server_hostname => "localhost",
    :server_port     => config[:listen_port],
    :username        => "test_user",
    :password        => "stack_pass",
    :lobby_name      => "test_lobby",
    :lobby_password  => "test",
    :character_name  => "test_character"
}

Log.setup("Main", "local")

$server = GameServer.new("test", Time.now.to_i, "latest.repro")
$client = StackClient.new($client_config)

trap_signals do
    # TODO - Save the game here so that we don't lose progress
    $server.stop if $server
    $client.stop if $client
    MeteredMethods.report
    exit
end

$server.start

$client.stack.set_state(:join_lobby)
$client.stack.specify_response_for(:choose_from_list, :field => :server_menu) do |stack, message|
    if stack.get_state == :join_lobby
        puts "Attempting to join lobby #{$client_config[:lobby_name]}/#{$client_config[:lobby_password]}"
        stack.put_response(:join_lobby)
    else
        puts "Attempting to create lobby #{$client_config[:lobby_name]}/#{$client_config[:lobby_password]}"
        stack.put_response(:create_lobby)
    end
end
$client.stack.specify_response_for(:text_field, :field => :lobby_name) do |stack, message|
    stack.put_response($client_config[:lobby_name])
end
$client.stack.specify_response_for(:text_field, :field => :lobby_password) do |stack, message|
    stack.put_response($client_config[:lobby_password])
end
$client.stack.specify_response_for(:join_fail) do |stack, message|
    stack.set_state(:create_lobby)
end
$client.stack.specify_response_for(:join_success) do |stack, message|
    LobbyState.new($client)
    $client.release_control
end

if __FILE__ == $0
    $client.start

    while $client.running?
        sleep 10
    end

    $server.stop
end
