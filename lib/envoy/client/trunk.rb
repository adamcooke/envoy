require 'envoy/protocol'
require 'envoy/client/channel'
require 'colorize'

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
        @log = STDERR
        if @options.has_key?(:log)
          @log = @options[:log] && File.open(@options[:log], "a")
        end
        log DEBUG, "envoy #{Envoy::VERSION} starting up"
      end
      
      def channels
        @channels ||= {}
      end
      
      def receive_start_tls
        log DEBUG, "Securing channel."
        start_tls
      end
      
      def receive_close id
        log TRACE, "closed stream #{id}"
        channels[id].close_connection true
        channels.delete(id)
      end
      
      def receive_stream id, data
        log TRACE, "#{data.length} bytes of data received on stream #{id}"
        channels[id].send_data data
      end
      
      def receive_connection id
        log TRACE, "New connection request with id `#{id}'"
        channels[id] = EM.connect(options[:local_host] || '127.0.0.1',
                                  options[:local_port], Channel, id, self)
      end
      
      def receive_keepalive
      end
      
      def log (level, text, io = @log)
        return unless io
        return unless level <= verbosity
        message = [
          @options[:timestamps] ? Time.now.strftime("%F %T") : nil,
          @options[:show_log_level] ? "#{VERBOSITIES[level][0]}:" : nil,
          text
        ].compact.join(" ")
        if @options[:color_log_level]
          #FATAL ERROR WARN\  INFO\  DEBUG TRACE
          message = message.colorize(%i"red red yellow green default light_black"[level])
        end 
        io.puts message
        io.flush
      end
      
      def receive_message text, level = INFO
        log level, text
      end
      
      def receive_ping
        log TRACE, "Server pinged. Ponging back."
        send_object :pong
      end
      
      def receive_halt
        @halting = true
        EventMachine.stop_event_loop
      end
      
      def receive_confirm (options)
        log DEBUG, "Server confirmed our request. Proxy set up."
      end
      
      def unbind
        if @halting
          log DEBUG, "Shutting down because server told us to."
        elsif $exiting
          log DEBUG, "Shutting down because the local system told us to."
        elsif !@halting && r = @options[:reconnect]
          log WARN, "Lost connection. Retrying..." if r == 0
          EM.add_timer 0.5 do
            @options[:reconnect] += 1
            Trunk.start @options
          end
        else
          if options[:did_connect]
            log FATAL, "Connection lost. Not point reconnecting because the host is randomly generated."
          else
            log FATAL, "Couldn't connect. Abandoning ship."
          end
          EventMachine.stop_event_loop
        end
      end
      
      def ssl_handshake_completed
        log DEBUG, "Channel is secure, sending options"
        options[:did_connect] = true
        options[:reconnect] = 0 if options[:hosts]
        send_object :options, options
        log DEBUG, "Exporting #{@options[:local_host]}:#{@options[:local_port]}"
      end
      
      def post_init
        self.comm_inactivity_timeout = 25
        log DEBUG, "Requesting TLS negotiation."
        send_object :start_tls
      end
      
    end
  
  end
end
