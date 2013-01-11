require 'rubygems'
require 'socket'
require 'openssl'
require './util/log'

$ruby_irc_version = "NinjaBot v0.1"

# Provides an interface for IRC users to interact with the server
class IRCConduit
    class << self
        public
        def start(server,port,nick,primary_callback)
            @server           = server
            @port             = port
            @nick             = nick
            @joined_chans     = []

            @version          = $ruby_irc_version

            @primary_callback = primary_callback
            @mutexes          = {}
            @buffers          = {}

            setup_ssl("data/cert.crt")
            connect
        end

        def puts(target, message)
            send_raw_message "PRIVMSG #{target} :#{message}"
        end

        # Blocking
        def gets(target)
            message = nil
            while message.nil?
                @mutexes[target].synchronize do
                    unless @buffers[target].empty?
                        message = @buffers.shift
                    end
                end
            end
            message
        end

        def stop
            disconnect
        end

        private
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

                    Log.debug("Using SSL")

                    ssl_socket
                else
                    tcp_socket
                end

                @primary_socket.connect
                @connected = true

                Log.debug("IRC Connected!")

                @listen_thread = Thread.new do
                    begin
                        Log.name_thread("IRC")
                        while true
                            read_buffer = @primary_socket.gets
                            if read_buffer.length > 0
                                process_raw_message(read_buffer)
                            end
                        end
                        Log.debug("Thread exiting")
                    rescue Exception => e
                        Log.debug(["Thread exited abnormally",e.message,e.backtrace])
                    end
                end

                Log.debug("Thread is listening")

                identify
            else
                Log.debug("IRC instance #{self.inspect} is already connected!")
            end
        end

        def disconnect
            if @connected
                Log.debug("Disconnecting from IRC")

                @sockets_to_close.each { |socket|
                    Log.debug("Closing socket #{socket.inspect}",3)
                    socket.close
                }
                @connected = false
            else
                Log.debug("IRC instance #{self.inspect} is not connected")
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
                Log.debug("Not active in channel #{channel_name}")
            else
                @joined_chans.reject { |c| c == channel_name }
            end
        end

        def send_raw_message(message)
            if @connected
                #Log.debug("Sent: #{message}")
                @primary_socket.puts(message)
            end
        end

        def process_raw_message(message)
            case message.strip
            when /^PING :(.+)$/i
                # IRC Heartbeat
                Log.debug("IRC Heartbeat from #{$1}")
                send_raw_message "PONG :#{$1}"
            when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.*)$/i
                # Private Message
                process_private_message $4, {
                    :agent => $1,
                    :user  => $2,
                    :host  => $3
                }
            else
                Log.debug("Rcvd: #{message}",8)
            end
        end

        def process_private_message(message, sender_params={})
            case message
            when /^([^:]+)\s:[\002]PING (.+)[\001]$/i
                # CCTP Ping
                Log.debug("CCTP Ping from #{sender_params[:agent]}!#{sender_params[:user]}@#{sender_params[:host]}",4)
                send_raw_message "NOTICE #{sender_params[:agent]} :\001PING #{$1}\001"
            when /^([^:]+)\s:[\001]VERSION[\001]$/i
                # CCTP Version
                Log.debug("CCTP Version from #{sender_params[:agent]}!#{sender_params[:user]}@#{sender_params[:host]}",4)
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
                Log.debug("~#{sender_params[:agent]} sends whisper:\n\t#{message}")
                to_parse = {
                    :message => message,
                    :type    => :whisper,
                    :params  => sender_params
                }
            elsif message.match /^[\001]ACTION (.+)[\001]$/i
                Log.debug("~#{sender_params[:agent]} performs action:\n\t#{$1}",3)
                to_parse = {
                    :message => "#{sender_params[:agent]} #{$1}",
                    :type    => :action,
                    :params  => sender_params
                }
            else
                Log.debug("~#{sender_params[:agent]} sends message:\n\t#{message}",3)
                to_parse = {
                    :message => message,
                    :params  => sender_params
                }
            end

            if to_parse
                begin
                    case to_parse[:type]
                    when :whisper
                        user = to_parse[:params][:agent]
                        unless @mutexes[user]
                            @mutexes[user] = Mutex.new
                            @buffers[user] = []
                            @primary_callback.new_irc_user(user)
                        end
                        @mutexes[user].synchronize { @buffers[user] << message }
                    else
                        Log.debug("Ignoring message type #{to_parse[:type]}")
                    end
                rescue Exception => e
                    Log.debug("Failed to parse message - #{e.message}")
                end
            end
        end
    end
end
