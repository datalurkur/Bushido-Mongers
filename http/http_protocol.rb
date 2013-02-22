require 'digest/sha1'
require 'base64'

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
        attr_accessor :status, :status_code, :data, :content_type, :headers
        def initialize(status, status_code, data=nil, content_type="text/html")
            @status       = status
            @status_code  = status_code
            @headers      = {}
            @data         = data
            @content_type = content_type

            #@use_compression = :gzip
        end

        def pack
            status = [
                HTTP.version_string,
                @status_code,
                @status
            ].join(" ")

            parts = [status]

            if @data
                case @use_compression
                when :gzip
                    @data = @data.gzip
                    @headers["Content-Encoding"] = "gzip"
                when :deflate
                    # FIXME - Broken on IE
                    @data = @data.deflate
                    @headers["Content-Encoding"] = "deflate"
                when nil
                else
                    Log.error("Unknown compression type #{@use_compressiong}")
                end
                @headers["Content-Length"]   = @data.length.to_s
                @headers["Content-Type"]     = @content_type
            end

            parts << @headers.collect { |k,v| HTTP.pack_header(k,v) }
            parts << ""
            parts << @data || ""

            parts.join("\r\n")
        end

        class SwitchingProtocols < Response
            GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
            
            def initialize(key)
                super("Switching Protocols", 101)
                headers["Connection"]             = "Upgrade"
                headers["Upgrade"]                = "websocket"
                headers["Sec-WebSocket-Accept"]   = Base64.encode64(Digest::SHA1.digest(key + GUID)).chomp
                #headers["Sec-WebSocket-Protocol"] = "chat"
            end
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
