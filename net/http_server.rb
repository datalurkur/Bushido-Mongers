require 'erb'
require 'socket'
require './net/socket_utils'
require './net/http_protocol'
require './util/compression'

class HTTPReader
    def initialize
        @current_request = nil
    end

    def read(socket)
        buffer = socket.gets
        raise Errno::ECONNRESET if buffer.nil?

        if buffer.gsub(/\s+/, '').empty?
            ret,@current_request = [@current_request,nil]
            return ret
        end

        unless @current_request
            method, uri, version_string = buffer.split(/\s+/)
            version = version_string.split(/\//).last.to_f
            raise "HTTP version mismatch #{version} / #{HTTP::VERSION}" unless version == HTTP::VERSION
            @current_request = HTTP::Request.new(method, nil, uri)
        else
            k,v = buffer.split(/:\s+/)
            @current_request.headers[k] = v
            @current_request.host = v if k.match(/host/i)
        end

        return nil
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
            Log.debug("Accepting connection from", 8)
            begin
                reader = HTTPReader.new
                while true
                    request = reader.read(socket)
                    if request
                        start = Time.now
                        Log.debug("HTTP request received", 8)
                        response = process_request(request)
                        processed = Time.now
                        socket.puts(response)
                        sent = Time.now
                        Log.debug("Responded to request in #{sent - start} seconds (Processed in #{processed - start} seconds, send in #{sent - processed} seconds)", 6)
                    end
                end
            rescue Errno::ECONNRESET
                Log.debug("Client disconnected", 8)
            rescue Exception => e
                Log.debug(["Thread exited abnormally", e.message, e.backtrace])
            end
        end
        @client_mutex.synchronize {
            @clients[socket] = client_thread
        }
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
                return HTTP::Response::OK.new(data, type).pack unless data.nil?
            rescue Exception => e
                Log.debug(["Failed to check uri match #{regex.inspect}", e.message, e.backtrace])
            end
        end
        Log.debug("URI #{request.uri} not found", 6)

        return HTTP::Response::NotFound.new.pack
    end

    def wildcard
        "([^\/]*)"
    end

    def add_route(uri_regex, &block)
        @responses[uri_regex] = block
    end

    def process_template(template_name, object_binding, args=[])
        begin
            template_filename = File.join(@web_root, template_name)
            template_data     = File.read(template_filename)
            renderer          = ERB.new(template_data)
            data              = renderer.result(object_binding)
            type              = "text/html"
            [data, type]
        rescue Exception => e
            Log.error(["Failed to process template #{template_name}", e.message, e.backtrace])
            nil
        end
    end

    def find_file(filename)
        begin
            file_request   = File.join(@web_root, filename)
            unless File.exist?(file_request)
                Log.debug("#{file_request} does not exist", 7)
                return nil
            end
            if File.directory?(file_request)
                Log.debug("#{file_request} is a directory", 7)
                return nil
            end
            Log.debug("Loading #{file_request}", 7)
            data           = File.read(file_request)

            file_extension = file_request.split(/\./).last
            type = case file_extension
            when "ico";        "image/x-icon"
            when "png";        "image/png"
            when "jpg","jpeg"; "image/jpeg"
            when "css";        "text/css"
            when "html";       "text/html"
            when "ttf";        "font/ttf"
            else
                Log.warning("Unrecognized extension #{file_extension}")
                "text/plain"
            end
            [data, type]
        rescue Exception => e
            Log.debug(["Failed to load data from #{filename}", e.message, e.backtrace])
            nil
        end
    end
end
