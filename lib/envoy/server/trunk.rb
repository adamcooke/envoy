require 'envoy/protocol'

module Envoy
  module Server
    module Trunk
      include Protocol
      
      def self.trunks
        @trunks ||= Hash.new{|h,k|h[k] = []}
      end
      
      def hosts
        @hosts ||= []
      end
      
      def channels
        @channels ||= {}
      end
      
      def receive_close id
        if chan = channels[id]
          chan.web.close_connection(true)
          channels.delete id
        end
      end
      
      def receive_start_tls
        send_object :start_tls
        start_tls
      end
      
      def receive_stream id, data
        channels[id].web.send_data data
      end
      
      def receive_options options
        @options = options
        hosts = @options[:hosts] || []
        hosts.delete_if do |label|
          if label == "s"
            send_object :message, "`s' is a reserved label"
            true
          elsif label =~ /\./
            send_object :message, "labels may not contain dots"
            true
          end
        end
        hosts << SecureRandom.random_number(36 ** 4).to_s(36) if hosts.empty?
        m = ["Local server on port #{options[:local_port]} is now publicly available via:"]
        @hosts = hosts.each do |host|
          Trunk.trunks[host] << self
          m << "http://#{host}.#{$zone}/"
        end
        send_object :message, m.join("\n")
      end
      
      def unbind
        hosts.each do |host|
          Trunk.trunks[host].delete self
        end
      end
      
    end
  end
end

