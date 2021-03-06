require 'envoy/protocol'
require 'envoy/utils'

module Envoy
  module Server
    module Trunk
      include Protocol
      
      def initialize key
        super
        @key = key
      end
      
      def self.trunks
        @trunks ||= Hash.new{|h,k|h[k] = []}
      end
      
      def post_init
        self.comm_inactivity_timeout = 60
      end
      
      def hosts
        @hosts ||= []
      end
      
      def channels
        @channels ||= {}
      end
      
      def key
        @options[:key]
      end
      
      def log (*args)
        Envoy.log(*args)
      end
      
      def message (level, message)
        if @options[:verbosity]
          send_object :message, message, level
        else
          send_object :message, message
        end
      end
      
      def halt message = nil
        message Envoy::FATAL, message if message
        send_object :halt
        close_connection(true)
      end
      
      def version? *requirement
        Gem::Requirement.new(*requirement) =~ Gem::Version.new(@options[:version])
      end
      
      def receive_start_tls
        send_object :start_tls
        start_tls
      end
      
      def receive_pong
        unless @pinged
          send_object :ping
          @pinged = true
        else
          EM.add_timer 30 do
            send_object :ping
          end
        end
      end
      
      def receive_close id, code = nil
        if chan = channels[id]
          chan.web.close(code)
          channels.delete id
        end
      end
      
      def receive_stream id, data
        c = channels[id]
        w = c && c.web
        w && w.send_data(data)
      end
      
      def receive_options options
        @options = options
        receive_pong if version? "> 0.1"
        if version? "< #{Envoy::VERSION}"
          message Envoy::WARN, "Your client is out of date. Please upgrade to #{Envoy::VERSION}."
        elsif version? "> #{Envoy::VERSION}"
          message Envoy::WARN, "Your client is from the future. The server is expecting #{Envoy::VERSION}."
        end
        if @key and @key != @options[:key]
          halt "Key is invalid"
          return
        end
        hosts = @options[:hosts] || []
        hosts.any? do |label|
          if label == "s"
            message Envoy::FATAL, "label is reserved: `#{label}'"
            true
          elsif label =~ /\./
            message Envoy::FATAL, "label is invalid: `#{label}'"
            true
          elsif other_trunk = Trunk.trunks[label][0]
            unless other_trunk.key == key
              message Envoy::FATAL, "label is protected with a key: `#{label}'"
              true
            end
          end
        end && halt
        if hosts.empty?
          hosts = [SecureRandom.random_number(36 ** 4).to_s(36)]
        end
        @hosts = hosts.each do |host|
          Trunk.trunks[host] << self
          message Envoy::INFO, "Service accessible at http://#{host}.#{$zone}/"
        end
        unless @options[:key]
          @options[:key] = SecureRandom.hex(8)
          message Envoy::INFO, "Service access key is `#{@options[:key]}'"
        end
        send_object :confirm, @options if version? ">= 0.2.2"
      end
      
      def unbind
        hosts.each do |host|
          Trunk.trunks[host].delete self
        end
      end
      
    end
  end
end

