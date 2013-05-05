require 'envoy/protocol'
require 'envoy/client/channel'

module Envoy
  module Client
  
    module Trunk
      include Protocol
      
      attr_reader :options
      
      def initialize options
        @options = options
      end
      
      def channels
        @channels ||= {}
      end
      
      def receive_start_tls
        start_tls
      end
      
      def receive_close id
        channels[id].close_connection true
        channels.delete(id)
      end
      
      def receive_stream id, data
        channels[id].send_data data
      end
      
      def receive_connection id
        channels[id] = EM.connect(options[:local_host] || '127.0.0.1',
                                  options[:local_port], Channel, id, self)
      end
      
      def receive_keepalive
      end
      
      def receive_message message
        STDERR.puts message
      end
      
      def receive_halt
        EventMachine.stop_event_loop
      end
      
      def unbind
        EM.stop_event_loop
      end
      
      def ssl_handshake_completed
        o = options.dup
        o.delete(:local_host)
        send_object :options, o
      end
      
      def post_init
        send_object :start_tls
      end
      
    end
  
  end
end

