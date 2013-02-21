require './util/traps'
require './util/timer'
require './net/game_server'
require './net/stack_client'

$client_config = {
    :server_hostname => "localhost",
    :server_port     => DEFAULT_LISTEN_PORT,
    :username        => "test_user",
    :password        => "stack_pass",
    :lobby_name      => "test_lobby",
    :lobby_password  => "test",
}

Log.setup("Main", "local")

# DEBUG
require './game/test/character'
recreate_test_character("test_user", "default")

$server = GameServer.new("test")
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
$client.stack.specify_response_for(:choose_from_list, {:field => :server_menu}) do |stack, message|
    if stack.get_state == :join_lobby
        puts "Attempting to join lobby #{$client_config[:lobby_name]}/#{$client_config[:lobby_password]}"
        stack.put_response(:join_lobby)
    else
        puts "Attempting to create lobby #{$client_config[:lobby_name]}/#{$client_config[:lobby_password]}"
        stack.put_response(:create_lobby)
    end
end
$client.stack.specify_response_for(:text_field, {:field => :lobby_name}) do |stack, message|
    stack.put_response($client_config[:lobby_name])
end
$client.stack.specify_response_for(:text_field, {:field => :lobby_password}) do |stack, message|
    stack.put_response($client_config[:lobby_password])
end
$client.stack.specify_response_for(:join_fail) do |stack, message|
    stack.set_state(:create_lobby)
end
$client.stack.specify_response_for(:create_fail) do |stack, message|
    $client_config[:lobby_name] += "_"
end
[:join_success, :create_success].each do |msg|
    $client.stack.specify_response_for(msg) do |stack, message|
        stack.set_state(:generate_game)
    end
end
$client.stack.specify_response_for(:choose_from_list, {:field => :lobby_menu}) do |stack, message|
    case stack.get_state
    when :generate_game
        stack.put_response(:generate_game)
    when :start_game
        stack.put_response(:start_game)
    when :select_character
        stack.put_response(:select_character)
    end
end
$client.stack.specify_response_for(:generation_success) do |stack, message|
    stack.set_state(:start_game)
end
$client.stack.specify_response_for(:generation_fail) do |stack, message|
    if message.reason == :already_generated
        stack.set_state(:start_game)
    else
        puts "Couldn't generate world - #{message.reason}"
        $client.release_control
    end
end
$client.stack.specify_response_for(:start_success) do |stack, message|
    stack.set_state(:select_character)
end
$client.stack.specify_response_for(:start_fail) do |stack, message|
    if message.reason == :already_started
        stack.set_state(:select_character)
    else
        puts "Couldn't start game - #{message.reason}"
        $client.release_control
    end
end
$client.stack.specify_response_for(:choose_from_list, {:field => :character}) do |stack, message|
    stack.put_response(message.choices.rand)
end
$client.stack.specify_response_for(:character_ready) do |stack, message|
    stack.clear_state
end
$client.stack.specify_response_for(:begin_playing) do |stack, message|
    $client.release_control
end

$client.start

while $client.running?
    sleep 10
end
