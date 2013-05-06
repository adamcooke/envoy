
require 'envoy/server/channel'

module Envoy
  module Server
    module Web
      include EM::P::LineText2
      
      def post_init
        @header = ""
      end
      
      def unbind
        @channel.trunk.channels.delete @channel.id if @channel
      end
      
      def receive_line line
        @header << line + "\r\n"
        if line =~ /^Host: ([^:]*)/
          host = $1
          raise "Request is not in #{$zone}" unless host.end_with?($zone)
          host = host[0...-$zone.length]
          host = host.split(".").last
          trunk = Trunk.trunks[host].sample || raise("No trunk for #{host}.#{$zone}")
          @channel = Channel.new(trunk, self, @header)
          set_text_mode
        elsif @header.size > 4096
          raise "Header's too long for my liking"
        end
      rescue RuntimeError => e
        send_data "HTTP/1.0 500 Internal Server Error\r\n"
        send_data "Content-Type: text/plain\r\n"
        send_data "\r\n"
        send_data "#{e.message}\r\n"
        close_connection true
      end
      
      def receive_binary_data data
        @channel.stream data
      end
      
    end
  end
end
