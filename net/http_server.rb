require 'socket'
require 'thread'

require './net/http_reader'

class HTTPServer
    attr_reader :web_root, :port

    def initialize(web_root, port)
        @port          = port
        @responses     = {}
        @route_order   = []

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

    def process_exchanges(socket, protocol=:http)
        Thread.new do
            reader          = HTTPReader.new
            preserve_socket = false

            begin
                while true
                    data = reader.read(socket)
                    if data
                        start = Time.now
                        response, close_socket = [nil, nil]
                        case data.method
                        when /get/i
                            Log.debug(["Get request for #{data.uri}", data.headers], 8)
                            match_result = match_response(data.uri)
                            response_match, match_data = match_result

                            if response_match.nil?
                                socket.write(HTTP::Response::NotFound.new)
                            else
                                upgrade = data.headers["Upgrade"] || data.headers["upgrade"]
                                if upgrade && upgrade.match(/websocket/i)
                                    Log.debug("Upgrading to websocket and setting responder to #{response_match.inspect}")
                                    websocket_key = data.headers["Sec-WebSocket-Key"]
                                    http_payload  = HTTP::Response::SwitchingProtocols.new(websocket_key)
                                    socket.write(http_payload.pack)

                                    # Transfer control to the web socket client and break
                                    response_match[:block].call(socket)
                                    preserve_socket = true
                                    break
                                else
                                    response = process_request(response_match, match_data)
                                    socket.write(response) if response
                                    break if data.headers["Connection"] && data.headers["Connection"].match(/close/i)
                                end
                            end
                        #when /post/i
                        #when /put/i
                        else
                            raise(NotImplementedError, "#{data.method} requests not supported")
                        end
                    end
                end
            rescue Errno::ECONNRESET,EOFError
                Log.debug("Client disconnected", 7)
            rescue Exception => e
                Log.debug(["Thread exited abnormally", e.message, e.backtrace])
            end

            unless preserve_socket
                @client_mutex.synchronize do
                    socket.close unless socket.closed?
                    @clients.delete(socket)
                end
            end
        end
    end
 
    def match_response(uri)
        @route_order.each do |regex|
            m = uri.match(regex)
            return [@responses[regex], m.captures] if m
        end
        return [nil, nil]
    end

    def process_request(match, match_data=nil)
        begin
            response_data, type = match[:block].call(match_data)
            return HTTP::Response::OK.new(response_data, type).pack
        rescue Exception => e
            Log.debug(["Failed to process request", e.message, e.backtrace])
            return HTTP::Response::NotFound.new.pack
        end
    end

    def add_route(uri_regex, type=:normal, &block)
        raise(ArgumentError, "Route already exists") if @responses.has_key?(uri_regex)
        Log.debug("Adding route at #{uri_regex}")
        @route_order << uri_regex
        @responses[uri_regex] = {:type => type, :block => block}
    end
end
