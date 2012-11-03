require 'rubygems'
require 'socket'
require 'openssl'

require 'server'

$ruby_irc_version = "RubyBot v0.1"

class IRCServer < Server
    def setup_ssl(cert_path="")
        @ssl         = true
        @ssl_context = OpenSSL::SSL::SSLContext.new

        if cert_path.length > 0
            cert_file         = File.read(cert_path)
            cert_data         = OpenSSL::X509::Certificate.new(cert_file)
            @ssl_context.cert = cert_data
        end
    end

    def connect
        unless @connected
            tcp_socket = TCPSocket.new(@server, @port)
            @sockets_to_close = [tcp_socket]

            @primary_socket = if @ssl
                ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, @ssl_context)
                @sockets_to_close = [ssl_socket]
                ssl_socket.sync_close = true

                debug("Using SSL")

                ssl_socket
            else
                tcp_socket
            end

            @primary_socket.connect
            @connected = true

            debug("IRC Connected!")

            @listen_thread = Thread.new("listen thread") do
                while true
                    read_buffer = @primary_socket.gets
                    if read_buffer.length > 0
                        process_message(read_buffer)
                    end
                end
                debug("Thread exiting")
            end

            debug("Thread is listening")

            identify
        else
            debug("IRC instance #{self.inspect} is already connected!")
        end
    end

    def disconnect
        if @connected
            debug("Disconnecting from IRC")

            @sockets_to_close.each { |socket|
                debug("Closing socket #{socket.inspect}",3)
                socket.close
            }
            @connected = false
        else
            debug("IRC instance #{self.inspect} is not connected")
        end
    end

    def identify(user_info="derp derp derp :derp derp")
        send_raw_message "USER #{user_info}"
        set_nick(@nick)
    end

    def set_nick(nickname)
        @nick = nickname
        send_raw_message "NICK #{@nick}"
    end

    def join_channel(channel_name)
        send_raw_message "JOIN #{channel_name}"
        @joined_chans << channel_name
    end

    def part_channel(channel_name)
        if @joined_chans.index(channel_name).nil?
            debug("Not active in channel #{channel_name}")
        else
            @joined_chans.reject { |c| c == channel_name }
        end
    end

    def send_raw_message(message)
        if @connected
            #debug("Sent: #{message}")
            @primary_socket.puts(message)
        end
    end

    def process_message(message)
        case message.strip
        when /^PING :(.+)$/i
            # IRC Heartbeat
            debug("IRC Heartbeat from #{$1}")
            send_raw_message "PONG :#{$1}"
        when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.*)$/i
            # Private Message
            process_private_message $4, {
                :agent => $1,
                :user  => $2,
                :host  => $3
            }
        else
            debug("Rcvd: #{message}",8)
        end
    end

    def process_private_message(message, sender_params={})
        case message
        when /^([^:]+)\s:[\002]PING (.+)[\001]$/i
            # CCTP Ping
            debug("CCTP Ping from #{sender_params[:agent]}!#{sender_params[:user]}@#{sender_params[:host]}",4)
            send_raw_message "NOTICE #{sender_params[:agent]} :\001PING #{$1}\001"
        when /^([^:]+)\s:[\001]VERSION[\001]$/i
            # CCTP Version
            debug("CCTP Version from #{sender_params[:agent]}!#{sender_params[:user]}@#{sender_params[:host]}",4)
            send_raw_message "NOTICE #{sender_params[:agent]} :\001VERSION #{@version}\001"
        when /^([^:]+)\s:(.+)$/i
            # Chan message
            channel = $1
            message = $2

            process_message_text(message, sender_params.merge(:channel => channel))
        end
    end

    def process_message_text(message, sender_params={})
        if sender_params[:channel] == @nick
            debug("~#{sender_params[:agent]} sends whisper:\n\t#{message}")
            to_parse = {
                :message => message,
                :type    => :whisper,
                :params  => sender_params
            }
        elsif message.match /^[\001]ACTION (.+)[\001]$/i
            debug("~#{sender_params[:agent]} performs action:\n\t#{$1}",3)
            to_parse = {
                :message => "#{sender_params[:agent]} #{$1}",
                :type    => :action,
                :params  => sender_params
            }
        else
            debug("~#{sender_params[:agent]} sends message:\n\t#{message}",3)
            to_parse = {
                :message => message,
                :params  => sender_params
            }
        end

        if to_parse
            begin
                case to_parse[:type]
                when :whisper
                    process_client_command(to_parse[:params][:agent],to_parse[:message])
                else
                    debug("Ignoring message type #{to_parse[:type]}")
                end
            rescue Exception => e
                debug("Failed to parse message - #{e.message}")
            end
        end
    end

    def start(server,port,nick)
        @server       = server
        @port         = port
        @nick         = nick
        @joined_chans = []

        @version      = $ruby_irc_version

        setup_ssl("cert.crt")
        connect

        super()
    end

    def send(target, message)
        send_raw_message "PRIVMSG #{target} :#{message}"
    end

    def stop
        super()

        disconnect
    end
end
