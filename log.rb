$debug_files = {
    "./message.rb" => 2,
    "./client.rb"  => 2
}
$max_log_level = 9 
$longest_file  = 0

def debug(msg,level=1)
    file,line = caller[0].split(/:/)
    $debug_files[file] ||= $max_log_level

    if level <= $debug_files[file]
        $longest_file = [$longest_file,file.to_s.length].max
        if Hash === msg
            msg.each { |l| debug_line(file,line,level,l) }
        elsif Array === msg
            msg.flatten.each { |l| debug_line(file,line,level,l) }
        else
            debug_line(file,line,level,msg)
        end
    end
end

def debug_line(file,line,level,msg)
    puts "#{file.to_s.rjust($longest_file)}:#{line.to_s.ljust(3)} (#{level.to_s.ljust($max_log_level.to_s.length)}) | #{msg}"
end
