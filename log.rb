# Threadsafe logging that logs the name of the thread, the file and line number, log level, and log message
# Requires setup
# Functions as a singleton
class Log
    class << self
        def setup(name="Main thread")
            @log_mutex = Mutex.new
            @default_thread_name = "Unnamed"

            @max_log_level       = 9
            @longest_file        = 0
            @longest_thread_name = @default_thread_name.length

            @log_files   = {}
            @log_threads = {}

            @logging_setup = true

            name_thread(name)
            debug("Logging begins")
        end

        # THREADSAFE
        def name_thread(name)
            raise "Logging system never initialized" unless @logging_setup
            @log_mutex.synchronize do
                @log_threads[Thread.current] = name
                @longest_thread_name = [@longest_thread_name,name.length].max
            end
        end

        # THREADSAFE
        def debug(msg, level=1)
            raise "Logging system never initialized" unless @logging_setup
            @log_mutex.synchronize do
                file,line = caller[2].split(/:/)
                @log_files[file] ||= @max_log_level
                thread_name = @log_threads[Thread.current] || @default_thread_name

                if level <= @log_files[file]
                    @longest_file = [@longest_file, file.to_s.length].max
                    if Hash === msg
                        msg.each { |l| debug_line(thread_name, file, line, level, l) }
                    elsif Array === msg
                        msg.flatten.each { |l| debug_line(thread_name, file, line, level, l) }
                    else
                        debug_line(thread_name, file, line, level, msg)
                    end
                end
            end
        end

        # NOT THREADSAFE
        def debug_line(thread_name, file, line, level, msg)
            puts "[#{thread_name.ljust(@longest_thread_name)}] #{file.to_s.ljust(@longest_file)}:#{line.to_s.ljust(3)} (#{level.to_s.ljust(@max_log_level.to_s.length)}) | #{msg}"
        end
    end
end
