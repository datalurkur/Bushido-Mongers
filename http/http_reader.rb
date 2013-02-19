require './http/http_protocol'
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
            Log.debug(["Error reading data", e.message])
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

