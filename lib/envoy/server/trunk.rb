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
      
      def key
        @options[:key]
      end
      
      def halt
        send_object :halt
        close_connection(true)
      end
      
      def receive_options options
        @options = options
        hosts = @options[:hosts] || []
        hosts.any? do |label|
          if label == "s"
            send_object :message, "#{label}: label is reserved"
            true
          elsif label =~ /\./
            send_object :message, "#{label}: labels may not contain dots"
            true
          elsif other_trunk = Trunk.trunks[label][0]
            unless other_trunk.key == key
              send_object :message, "#{label}: label in use, and you don't have the key"
              true
            end
          end
        end && halt
        hosts << SecureRandom.random_number(36 ** 4).to_s(36) if hosts.empty?
        m = ["#{options[:local_host]}:#{options[:local_port]} now available at:"]
        @hosts = hosts.each do |host|
          Trunk.trunks[host] << self
          m << "http://#{host}.#{$zone}/"
        end
        @options[:key] ||= SecureRandom.hex(8)
        send_object :message, m.join(" ")
        send_object :message, "Your key is #{@options[:key]}"
      end
      
      def unbind
        hosts.each do |host|
          Trunk.trunks[host].delete self
        end
      end
      
    end
  end
end

