
require 'envoy/server/channel'

module Envoy
  module Server
    module Web
      include EM::P::LineText2
      
      def post_init
        @header = ""
        @connection = "close"
      end
      
      def send_page status, message
        send_data "HTTP/1.0 #{status} Message\r\n"
        send_data "Content-Type: text/plain\r\n"
        send_data "\r\n"
        send_data "#{message}\r\n"
      end
      
      def close code
        case code
        when 502
          send_page code, "The service isn't running, and couldn't be started." 
        end
        close_connection(true)
      end
      
      def unbind
        @channel.trunk.channels.delete @channel.id if @channel
      end
      
      def receive_line line
        @first_line ||= line
        if line == ""
          trunk = Trunk.trunks[@host].sample || raise("No trunk for #{@host}.#{$zone}")
          @header << "Connection: #{@connection}\r\n\r\n"
          @channel = Channel.new(trunk, self, @header)
          @channel.message "%s %s" % [Socket.unpack_sockaddr_in(get_peername)[1], @first_line]
          set_text_mode
        elsif line =~ /^connection:\s*upgrade$/i
          @connection = "upgrade"
        elsif line =~ /^keep-alive:/i
        elsif line =~ /^host:\s*([^:]*)/i
          @host = $1
          raise "Request for #{@host} is not in #{$zone}" unless @host.end_with?($zone)
          @host = @host[0...-$zone.length]
          @host = @host.split(".").last
          @header << line + "\r\n"
        elsif @header.size > 4096
          raise "Header's too long for my liking"
        else
          @header << line + "\r\n"
        end
      rescue RuntimeError => e
        send_page 500, e.inspect
        close_connection true
      end
      
      def receive_binary_data data
        @channel.stream data
      end
      
    end
  end
end
