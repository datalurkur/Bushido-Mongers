require 'thread'
require 'util/formatting'

# Threadsafe logging that logs the name of the thread, the file and line number, log level, and log message
# Requires setup
# Functions as a singleton
class Log
    class << self
        LOG_DIR    = "logs"
        LOG_CONFIG = "log.cfg"

        def setup(name, logfile_prefix, logfile_behavior=:terse)
            $stdout.sync = true

            @log_mutex = Mutex.new
            @default_thread_name = "Unnamed"

            @max_log_level       = 9
            @longest_file        = 0
            @longest_thread_name = @default_thread_name.length

            @source_files   = {}
            @source_threads = {}

            @verbose_logfile  = File.open(File.join(get_log_directory, "#{logfile_prefix}_verbose.log"), "w")
            @filtered_logfile = File.open(File.join(get_log_directory, "#{logfile_prefix}_output.log"),  "w")
            @logfile_behavior = logfile_behavior

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
        def warning(msg, level=1)
            # FIXME - Make this look different from a debug message - color perhaps?
            debug(msg, level)
        end

        def debug(msg, level=1)
            raise "Logging system never initialized" unless @logging_setup
            @log_mutex.synchronize do
                file,line = caller[2].split(/:/)
                @source_files[file] ||= @max_log_level
                thread_name = @source_threads[Thread.current] || @default_thread_name

                to_print = (Array === msg) ? msg : [msg]
                to_print.each do |m|
                    if level <= @source_files[file]
                        print_line(m, thread_name, file, line, level, Kernel)
                        print_line(m, thread_name, file, line, level, @filtered_logfile) unless @logfile_behavior == :none
                    end
                    print_line(m, thread_name, file, line, level, @verbose_logfile) if @logfile_behavior == :verbose
                end
            end
        end

        private
        # NOT THREADSAFE
        def print_line(msg, thread_name, file, line, level, handle, prefix=nil)
            @longest_file = [@longest_file, file.to_s.length].max

            msg_prefix = prefix || "[#{thread_name.ljust(@longest_thread_name)}] #{file.to_s.ljust(@longest_file)}:#{line.to_s.ljust(3)} (#{level.to_s.ljust(@max_log_level.to_s.length)}) | "

            case msg
            when Array, Hash
                handle.puts msg.to_formatted_string(msg_prefix)
            when String
                handle.puts(msg_prefix + msg)
            else
                handle.puts(msg_prefix + msg.inspect)
            end
        end
    end
end
