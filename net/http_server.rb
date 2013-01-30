require 'socket'
require 'thread'
require './net/http_protocol'
require './net/defaults'
require './util/compression'
require './util/log'

class HTTPReader
    def initialize
        @buffer = ""
        @current_request = nil
    end

    def read(socket)
        buffer = ""
        begin
            buffer = socket.read_nonblock(DEFAULT_BUFFER_SIZE)
            raise(Errno::ECONNRESET) if buffer.empty?
        rescue Errno::EWOULDBLOCK,Errno::EAGAIN
            IO.select([socket])
            retry
        rescue EOFError => e
            raise(e)
        rescue Exception => e
            Log.debug(["Error reading data", e.message, e.backtrace])
            raise(e)
        end

        @buffer += buffer

        while (index = @buffer.index(/\r\n/))
            line = @buffer[0...index]
            @buffer = @buffer[(index+2)..-1]
            if @current_request
                if line.empty?
                    if @current_request.method.match(/get/i)
                        ret, @current_request = [@current_request, nil]
                        return ret
                    else
                        raise(NotImplementedError, "Put / Post requests not supported.")
                    end
                else
                    # Assume we're parsing headers, since we don't support put / post yet
                    parse_header(line)
                end
            else
                new_request = parse_query(line)
                unless new_request
                    Log.warning("Malformed HTTP query - #{line.inspect}")
                    raise(StandardError, "Malformed data received from client.")
                end
                @current_request = new_request
            end
        end

        return nil
    end

    def parse_query(line)
        method, uri, version_string = line.split(/\s+/)
        version = version_string.split(/\//).last.to_f
        raise(StandardError, "HTTP version mismatch #{version} / #{HTTP::VERSION}.") unless version == HTTP::VERSION
        return HTTP::Request.new(method, nil, uri)
    end

    def parse_header(line)
        k,v = line.split(/:\s+/)
        @current_request.headers[k] = v
        @current_request.host = v if k.match(/host/i)
    end
end

class HTTPServer
    attr_reader :web_root, :port

    def initialize(web_root, port)
        @port          = port
        @responses     = {}

        @clients       = {}
        @client_mutex  = Mutex.new

        @listen_thread = nil
        @accept_socket = nil

        @web_root      = web_root
    end

    def start
        if @listen_thread || @accept_socket
            Log.warning("#{self.class} is already running")
            return
        end

        Log.debug("Web service starting on port #{@port.inspect}")
        @accept_socket = TCPServer.new(@port)
        @listen_thread = Thread.new do 
            Log.name_thread("http-a")
            Log.debug("Web service listening", 5)
            while(true)
                begin
                    # Accept the new connection
                    socket = @accept_socket.accept
                    Log.debug("Incoming HTTP connection from #{socket.addr.last}", 6)
                    thread = process_exchanges(socket)
                    @client_mutex.synchronize do
                        @clients[socket] = thread
                    end
                rescue Exception => e
                    Log.debug(["Failed to accept connection",e.message,e.backtrace])
                end
            end
        end 
    end

    def stop
        Log.debug("Web service stopping")
        if @listen_thread
            @listen_thread.kill
            @listen_thread = nil

            @accept_socket.close
            @accept_socket = nil
        end

        @client_mutex.synchronize do
            @clients.each do |k,v|
                v.kill if v.alive?
                k.close unless k.closed?
            end
            @clients.clear
        end
    end

    def process_exchanges(socket)
        Thread.new do
            begin
                reader = HTTPReader.new
                while true
                    request = reader.read(socket)
                    if request
                        start = Time.now
                        response = process_request(request)
                        processed = Time.now
                        socket.write(response)
                        sent = Time.now
                        Log.debug("Responded to request in #{sent - start} seconds (Processed in #{processed - start} seconds, send in #{sent - processed} seconds)", 6)
                        break
                    end
                end
            rescue Errno::ECONNRESET,EOFError
                Log.debug("Client disconnected", 7)
            rescue Exception => e
                Log.debug(["Thread exited abnormally", e.message, e.backtrace])
            end

            @client_mutex.synchronize do
                socket.close unless socket.closed?
                @clients.delete(socket)
            end
        end
    end

    def process_request(request)
        Log.debug("Processing request #{request.uri}", 6)

        data = nil
        type = nil
        @responses.keys.each do |regex|
            m = request.uri.match(regex)
            next unless m
            begin
                Log.debug("Attempting match #{regex.inspect}", 7)
                data, type = @responses[regex].call(m.captures)
                if data.nil?
                    Log.debug("Nil data for match #{regex.inspect}", 7)
                else
                    Log.debug("HTTP OK", 7)
                    return HTTP::Response::OK.new(data, type).pack
                end
            rescue Exception => e
                Log.debug(["Failed to check uri match #{regex.inspect}", e.message, e.backtrace])
            end
        end
        Log.debug("URI #{request.uri} not found", 6)
        return HTTP::Response::NotFound.new.pack
    end

    def add_route(uri_regex, &block)
        @responses[uri_regex] = block
    end
end
