
module Envoy
  
  module Client
    
    module Channel
      
      def initialize id, client
        @id, @client = id, client
        @buffer = ""
        super()
      end
      
      def connection_completed
        @client.log TRACE, "connected to upstream service for stream #{@id}"
        @tried_starting = nil
        send_data @buffer, true
        @buffer = nil
      end
      
      def send_data data, force = false
        if !@buffer or force
          super data
        else
          @buffer << data
        end
      end
      
      def receive_data data
        @client.log TRACE, "#{data.length} bytes of data send on stream #{@id}"
        @client.send_object :stream, @id, data
      end
      
      def reconnect
        @client.log TRACE, "reconnecting to upstream service for stream #{@id}"
        super @client.options[:local_host], @client.options[:local_port]
      end
      
      def unbind e
        if e == Errno::ECONNREFUSED
          @client.log ERROR, "couldn't connect to upstream service for stream #{@id}"
          @client.send_object :close, @id
        elsif e
          @client.log ERROR, e.inspect
          @client.send_object :close, @id
        else
          @client.log DEBUG, "upstream service closed stream #{@id}"
          @client.send_object :close, @id
        end
      end
      
    end
    
    def self.run (options = {})
      unless EM.reactor_running?
        EM.run do
          EM.add_periodic_timer(0.1) do
            $reloader.(0)
          end
          EM.connect options[:server_host], options[:server_port], self, options
        end
      end
    end
    
  end
  
end

