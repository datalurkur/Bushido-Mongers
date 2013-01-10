require 'socket'
require 'net/socket_utils'
require 'util/compression'

class HTTP
    VERSION = 1.1

    def self.pack_header(k,v)
        k + ": " + v
    end

    def self.version_string
        "HTTP/#{VERSION}"
    end

    class Request < HTTP
        attr_accessor :method, :uri, :host, :headers
        def initialize(method, host, uri)
            @method  = method
            @host    = host
            @uri     = uri

            @headers = {}
            @headers["Host"] = @host unless @host.nil?
        end

        def pack
            status = [
                method,
                uri,
                HTTP.version_string
            ].join(" ")

            [
                status,
                @headers.collect { |k,v| HTTP.pack_header(k,v) }
            ].join("\r\n")
        end

        class Get < Request
            def initialize(host, uri); super("GET", host, uri); end
        end
    end

    class Response < HTTP
        attr_accessor :status, :status_code, :data, :content_type
        def initialize(status, status_code, data=nil, content_type=nil)
            @status       = status
            @status_code  = status_code
            @data         = data
            @content_type = content_type

            @use_compression = true
        end

        def pack
            status = [
                HTTP.version_string,
                @status_code,
                @status
            ].join(" ")

            headers = {}

            if @data
                if @use_compression
                    @data = @data.deflate
                    headers["Content-Encoding"] = "deflate"
                end
                headers["Content-Length"] = @data.length.to_s
                headers["Content-Type"]   = @content_type
            end

            [
                status,
                headers.collect { |k,v| HTTP.pack_header(k,v) },
                "",
                @data
            ].join("\r\n")
        end

        class OK < Response
            def initialize(data=nil, content_type=nil)
                super("OK", 200, data, content_type)
            end
        end

        class NotFound < Response
            def initialize
                super("NOT FOUND", 404)
            end
        end
    end
end

class HTTPReader
    def initialize
        @current_request = nil
    end

    def read(socket)
        buffer = socket.gets
        raise Errno::ECONNRESET if buffer.nil?

        if buffer.gsub(/\s+/, '').empty?
            #Log.debug("Buffer is empty, returning finished request")
            ret = @current_request
            @current_request = nil
            return ret
        end

        unless @current_request
            method, uri, version_string = buffer.split(/\s+/)
            #Log.debug(["Request line: ", [method, uri, version_string]])
            version = version_string.split(/\//).last.to_f
            unless version == HTTP::VERSION
                Log.debug("Unsupported version #{version}")
                return nil
            end
            @current_request = HTTP::Request.new(method, nil, uri)
        else
            #Log.debug(["Received line: ", buffer])
            k,v = buffer.split(/:\s+/)
            @current_request.headers[k] = v
            if k == "Host"
                @current_request.host = v
            end
        end

        return nil
    end
end

class HTTPServer
    def initialize(port)
        @port          = port
        @responses     = {}

        @clients       = {}
        @client_mutex  = Mutex.new

        @listen_thread = nil
        @accept_socket = nil
    end

    def start
        if @listen_thread || @accept_socket
            Log.warning("#{self.class} is already running")
            return
        end

        Log.debug("Web service starting")
        @accept_socket = TCPServer.new(@port)
        @listen_thread = Thread.new do 
            Log.name_thread("http-a")
            Log.debug("Web service listening")
            while(true)
                begin
                    # Accept the new connection
                    socket = @accept_socket.accept
                    process_exchanges(socket)
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
        end
        if @accept_socket
            @accept_socket.close
            @accept_socket = nil
        end
        @client_mutex.synchronize {
            @clients.each do |k,v|
                v.kill
                k.close
            end
            @clients.clear
        }
    end

    def process_exchanges(socket)
        client_thread = Thread.new do
            Log.debug("Accepting connection from")
            begin
                reader = HTTPReader.new
                while true
                    request = reader.read(socket)
                    if request
                        Log.debug("HTTP request received")
                        response = process_request(request)
                        socket.write(response)
                    end
                end
            rescue Errno::ECONNRESET
                Log.debug("Client disconnected")
            rescue Exception => e
                Log.debug(["Thread exited abnormally", e.message, e.backtrace])
            end
        end
        @client_mutex.synchronize {
            @clients[socket] = client_thread
        }
    end

    def process_request(request)
        Log.debug("Processing request #{request.uri}")
        data = nil
        type = nil
        @responses.each do |regex,block|
            m = request.uri.match(regex)
            next unless m
            data,type = block.call(m.captures)
            next unless data
            type ||= "text/plain"
            break
        end
        if data
            HTTP::Response::OK.new(data, type).pack
        else
            Log.debug("No appropriate response found")
            HTTP::Response::NotFound.new.pack
        end
    end

    def wildcard
        "([^\/]*)"
    end

    def add_response(uri_regex, &block)
        return unless block_given?
        @responses[uri_regex] = block
    end
end
