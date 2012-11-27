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

                if level <= @source_files[file]
                    debug_line(thread_name, file, line, level, msg, Kernel)
                    debug_line(thread_name, file, line, level, msg, @filtered_logfile)
                end
                debug_line(thread_name, file, line, level, msg, @verbose_logfile)
            end
        end

private
        # NOT THREADSAFE
        def debug_line(thread_name, file, line, level, msg, handle, indent=0)
            @longest_file = [@longest_file, file.to_s.length].max

            msg_array = case msg
            when Array; msg
            when Hash;  ["{" + msg.collect { |k,v| "#{k.inspect} => #{v.inspect}" }.join(", ") + "}"]
            else;       [msg]
            end

            msg_array.each do |m|
                case m
                when Array, Hash
                    # Handle nested arrays
                    debug_line(thread_name, file, line, level, m, handle, indent+1)
                else
                    handle.puts "[#{thread_name.ljust(@longest_thread_name)}] #{file.to_s.ljust(@longest_file)}:#{line.to_s.ljust(3)} (#{level.to_s.ljust(@max_log_level.to_s.length)}) | #{"\t"*indent}#{m}"
                end
            end
        end
    end
end
