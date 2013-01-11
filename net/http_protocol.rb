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
        def initialize(status, status_code, data="", content_type="text/html")
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
