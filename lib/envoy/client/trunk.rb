require 'envoy/protocol'
require 'envoy/client/channel'

module Envoy
  module Client
  
    module Trunk
      include Protocol
      
      attr_reader :options
      
      def self.start options
        EM.connect options[:server_host], options[:server_port].to_i, Envoy::Client::Trunk, options
      end
      
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
        t = Time.now.strftime("%F %T")
        STDERR.puts t + " " + message.split("\n").join("\n#{t.gsub(/./, ' ')} ")
      end
      
      def receive_halt
        EventMachine.stop_event_loop
      end
      
      def unbind
        if r = @options[:reconnect]
          STDERR.write "Lost connection. Retrying... #{r[0]}\r"
          EM.add_timer 0.5 do
            @options[:reconnect] = r.rotate
            Trunk.start @options
          end
        else
          if options[:did_connect]
            STDERR.puts "Connection lost. Not point reconnecting because the host is randomly generated."
          else
            STDERR.puts "Couldn't connect. Abandoning ship."
          end
          receive_halt
        end
      end
      
      def ssl_handshake_completed
        options[:did_connect] = true
        options[:reconnect] = %w"- \\ | /" if options[:hosts]
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