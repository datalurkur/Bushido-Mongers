require './world/factories'
$TestWorldFactory = FantasmTestWorldFactory

require './run_local'

if __FILE__ == $0
    $client.start

    while $client.running?
        sleep 10
    end

    $server.stop
end
