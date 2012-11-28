require 'thread'

# Threadsafe logging that logs the name of the thread, the file and line number, log level, and log message
# Requires setup
# Functions as a singleton
class Log
    class << self
        LOG_DIR    = "logs"
        LOG_CONFIG = "log.cfg"

        def setup(name, logfile_prefix)
            @log_mutex = Mutex.new
            @default_thread_name = "Unnamed"

            @max_log_level       = 9
            @longest_file        = 0
            @longest_thread_name = @default_thread_name.length

            @source_files   = {}
            @source_threads = {}

            @verbose_logfile  = File.open(File.join(get_log_directory, "#{logfile_prefix}_verbose.log"), "w")
            @filtered_logfile = File.open(File.join(get_log_directory, "#{logfile_prefix}_output.log"),  "w")

            read_config

            @logging_setup = true

            name_thread(name)
            debug("Logging begins")
        end

        def read_config
            if File.exists?(LOG_CONFIG)
                config_data = File.read(LOG_CONFIG)
                config_data.split(/\n/).each do |line|
                    begin
                        file, level = line.strip.split(/ /)
                        @source_files[file] = level.to_i
                    rescue
                        Kernel.puts "Config section #{line.inspect} ignored"
                    end
                end
            end
        end

        def get_log_directory
            unless File.exists?(LOG_DIR)
                Dir.mkdir(LOG_DIR)
            end
            LOG_DIR
        end

        # THREADSAFE
        def name_thread(name)
            raise "Logging system never initialized" unless @logging_setup
            @log_mutex.synchronize do
                @source_threads[Thread.current] = name
                @longest_thread_name = [@longest_thread_name,name.length].max
            end
        end

        # THREADSAFE
        def debug(msg, level=1)
            raise "Logging system never initialized" unless @logging_setup
            @log_mutex.synchronize do
                file,line = caller[2].split(/:/)
                @source_files[file] ||= @max_log_level
                thread_name = @source_threads[Thread.current] || @default_thread_name

                to_print = (Array === msg) ? msg : [msg]
                to_print.each do |m|
                    if level <= @source_files[file]
                        debug_line(m, thread_name, file, line, level, Kernel)
                        debug_line(m, thread_name, file, line, level, @filtered_logfile)
                    end
                    debug_line(m, thread_name, file, line, level, @verbose_logfile)
                end
            end
        end

private
        # NOT THREADSAFE
        def debug_line(msg, thread_name, file, line, level, handle, prefix=nil)
            @longest_file = [@longest_file, file.to_s.length].max

            msg_prefix = prefix || "[#{thread_name.ljust(@longest_thread_name)}] #{file.to_s.ljust(@longest_file)}:#{line.to_s.ljust(3)} (#{level.to_s.ljust(@max_log_level.to_s.length)}) | "

            case msg
            when Array
                handle.puts(msg_prefix + "[")
                if msg.empty?
                    handle.puts(msg_prefix + "\t" + "<EMPTY>")
                else
                    msg.each do |element|
                        debug_line(element, thread_name, file, line, level, handle, msg_prefix + "\t")
                    end
                end
                handle.puts(msg_prefix + "]")
            when Hash
                handle.puts(msg_prefix + "{")
                if msg.empty?
                    handle.puts(msg_prefix + "\t" + "<EMPTY>")
                else
                    longest_key = msg.keys.inject(0) { |longest,key|
                        [key.inspect.length, longest].max
                    }
                    msg.each do |key, value|
                        output        = key.inspect.ljust(longest_key) + " => "
                        value_printed = false

                        unless (Array === value) || (Hash === value)
                            output += value.inspect
                            value_printed = true
                        end

                        handle.puts(msg_prefix + "\t" + output)
                        unless value_printed
                            debug_line(value, thread_name, file, line, level, handle, msg_prefix + "\t\t")
                        end
                    end
                end
                handle.puts(msg_prefix + "}")
            when String
                handle.puts(msg_prefix + msg)
            else
                handle.puts(msg_prefix + msg.inspect)
            end
        end
    end
end
