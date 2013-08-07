require 'envoy/protocol'

module Envoy
  module Server
    module Trunk
      include Protocol
      
      def log message
        t = Time.now.strftime("%F %T")
        STDERR.puts t + " " + message.split("\n").join("\n#{t.gsub(/./, ' ')} ")
      end
      
      def initialize key
        super
        @key = key
      end
      
      def self.trunks
        @trunks ||= Hash.new{|h,k|h[k] = []}
      end
      
      def post_init
        self.comm_inactivity_timeout = 25
      end
      
      def hosts
        @hosts ||= []
      end
      
      def channels
        @channels ||= {}
      end
      
      def receive_pong
        EM.add_timer 5 do
          log "ping"
          send_object :ping
        end
      end
      
      def receive_close id, code = nil
        if chan = channels[id]
          chan.web.close(code)
          channels.delete id
        end
      end
      
      def receive_start_tls
        send_object :start_tls
        start_tls
      end
      
      def receive_stream id, data
        c = channels[id]
        w = c && c.web
        w && w.send_data(data)
      end
      
      def key
        @options[:key]
      end
      
      def halt message = nil
        send_object :message, message if message
        send_object :halt
        close_connection(true)
      end
      
      def version? *requirement
        Gem::Requirement.new(*requirement) =~ Gem::Version.new(@options[:version])
      end
      
      def receive_options options
        @options = options
        if version? "~> 0.1"
          receive_pong
        end
        if version? "< #{Envoy::VERSION}"
          send_object :message, "Your client is out of date. Please upgrade to #{Envoy::VERSION}."
        end
        if @key and @key != @options[:key]
          halt "Key is invalid"
          return
        end
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
        send_object :message, m.join(" ")
        unless @options[:key]
          @options[:key] ||= SecureRandom.hex(8)
          send_object :message, "Your key is #{@options[:key]}"
        end
      end
      
      def unbind
        hosts.each do |host|
          Trunk.trunks[host].delete self
        end
      end
      
    end
  end
end

