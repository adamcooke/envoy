require 'envoy/protocol'
require 'envoy/client/channel'
require 'colorize'

module Envoy
  module Client
  
    module Trunk
      include Protocol
      
      attr_reader :config
      
      State = Struct.new(:connected, :reconnects)
      
      def self.start (config, state = State.new(false, 0))
        EM.connect(*config.server, Envoy::Client::Trunk, config, state)
      end
      
      def initialize (config, state)
        @config = config
        @state = state
      end
      
      def channels
        @channels ||= {}
      end
      
      def receive_start_tls
        log DEBUG, "Securing channel."
        start_tls
      end
      
      def receive_close id
        return unless channels[id]
        log TRACE, "closed stream #{id}"
        channels[id].close_connection true
        channels.delete(id)
      end
      
      def receive_stream id, data
        return unless channels[id]
        log TRACE, "#{data.length} bytes of data received on stream #{id}"
        channels[id].send_data data
      end
      
      def receive_connection id
        log TRACE, "New connection request with id `#{id}'"
        channels[id] = case @config.export[0]
          when :tcp
            EM.connect(*@config.export[1, 2], Channel, id, self)
          when :unix
            EM.connect_unix_domain(*@config.export[1], Channel, id, self)
          else
            raise @config.export[0].inspect
          end
      rescue
        send_object :close, id
      end
      
      def receive_keepalive
      end
      
      def receive_message text, level = INFO
        log level, text
      end
      
      def receive_ping
        unless @state.connected
          ssl_handshake_completed
        end
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
      
      def log (*args)
        Envoy.log(*args)
      end
      
      def unbind
        if @halting
          log DEBUG, "Shutting down because server told us to."
        elsif $exiting
          log DEBUG, "Shutting down because the local system told us to."
        elsif @state.connected
          log WARN, "Lost connection. Retrying..." if @state.reconnects == 0
          EM.add_timer 0.5 do
            @state.reconnects += 1
            Trunk.start(@config, @state)
          end
        else
          log FATAL, "Couldn't connect. Abandoning ship."
          EventMachine.stop_event_loop
        end
      end
      
      def ssl_handshake_completed
        log DEBUG, "Channel is secure, sending options"
        @state.connected = true
        send_object :options, @config.options
        log DEBUG, "Exporting #{@config.export.join(":")}"
      end
      
      def post_init
        self.comm_inactivity_timeout = 60
        log TRACE, "Requesting TLS negotiation."
        #send_object :start_tls
        send_object :pong
      end
      
    end
  
  end
end
