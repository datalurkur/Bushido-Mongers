require 'thread'
require 'util/formatting'

# Threadsafe logging that logs the name of the thread, the file and line number, log level, and log message
# Requires setup
# Functions as a singleton
class Log
    class << self
        LOG_DIR    = "logs"
        LOG_CONFIG = "log.cfg"

        def setup(name, logfile_prefix, logfile_behavior=:none)
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
        def error(msg, level=1)
            log_internal(msg, level, :red)
        end

        def warning(msg, level=1)
            log_internal(msg, level, :yellow)
        end

        def debug(msg, level=1)
            log_internal(msg, level, :white)
        end

        def log_internal(msg, level, color=:white)
            raise "Logging system never initialized" unless @logging_setup

            file,line = caller[1].split(/:/)
            @source_files[file] ||= @max_log_level
            return unless level <= @source_files[file] || @logfile_behavior == :verbose

            thread_name = @source_threads[Thread.current] || @default_thread_name

            to_print = (Array === msg) ? msg : [msg]
            printable_data = to_print.collect do |m|
                format_line(m, thread_name, file, line, level, color)
            end.join("\n")

            @log_mutex.synchronize do
                if level <= @source_files[file]
                    Kernel.puts printable_data
                    (@filtered_logfile.puts printable_data) unless @logfile_behavior == :none
                end
                (@verbose_logfile.puts printable_data) if @logfile_behavior == :verbose
            end
        end

        private
        def format_line(msg, thread_name, file, line, level, color)
            @longest_file = [@longest_file, file.to_s.length].max

            msg_prefix = "[#{thread_name.ljust(@longest_thread_name)}] #{file.to_s.ljust(@longest_file)}:#{line.to_s.ljust(3)} (#{level.to_s.ljust(@max_log_level.to_s.length)}) | "

            case msg
            when Array, Hash
                msg.to_formatted_string(msg_prefix)
            when String
                (msg_prefix + msg)
            else
                (msg_prefix + msg.inspect)
            end.color(color)
        end
    end
end
