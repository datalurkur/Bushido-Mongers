require './util/traps'
require './util/timer'
require './net/game_server'
require './net/stack_client'

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
$client.stack.specify_response_for(:join_success) do |stack, message|
    stack.set_state(:generate_game)
end
$client.stack.specify_response_for(:choose_from_list, {:field => :lobby_menu}) do |stack, message|
    case stack.get_state
    when :generate_game
        stack.put_response(:generate_game)
    when :start_game
        stack.put_response(:start_game)
    when :create_character
        stack.put_response(:create_character)
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
    stack.set_state(:create_character)
end
$client.stack.specify_response_for(:start_fail) do |stack, message|
    if message.reason == :already_started
        stack.set_state(:create_character)
    else
        puts "Couldn't start game - #{message.reason}"
        $client.release_control
    end
end
$client.stack.specify_response_for(:text_field, {:field => :character_name}) do |stack, message|
    stack.put_response($client_config[:character_name])
end
$client.stack.specify_response_for(:choose_from_list, {:field => :character_race}) do |stack, message|
    stack.put_response(message.choices.rand)
end
$client.stack.specify_response_for(:choose_from_list, {:field => :character_gender}) do |stack, message|
    stack.put_response(message.choices.rand)
end
$client.stack.specify_response_for(:choose_from_list, {:field => :character_options}) do |stack, message|
    stack.put_response(:create)
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
