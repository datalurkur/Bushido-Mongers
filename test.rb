require 'thread'

getthread = Thread.new { 
    while(true)
        input = gets
        puts "Got input #{input}"
    end
}

while(true)
    sleep(1)
    puts "."
end
