
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
          @client.log TRACE, "couldn't connect to upstream service for stream #{@id}"
          if @tried_starting
            if Time.now > @tried_starting + @client.options[:delay]
              @client.log ERROR, "Service isn't running, but starting it didn't really work out."
              @client.send_object :close, @id, 502
              @tried_starting = false
            else
              EM.add_timer 0.1 do
                reconnect
              end
            end
          elsif cmd = @client.options[:command]
            cmd = cmd % @client.options
            @client.log INFO, "Service doesn't seem to be running. Trying to start it now..."
            @tried_starting = Time.now
            p @client.options[:dir]
            Dir.chdir File.expand_path(@client.options[:dir]) do
              fork do
                ENV.delete("GEM_HOME")
                ENV.delete("GEM_PATH")
                ENV.delete("BUNDLE_BIN_PATH")
                ENV.delete("BUNDLE_GEMFILE")
                system cmd
              end
            end
            EM.add_timer 0.1 do
              reconnect
            end
          end
        elsif e
          @client.log ERROR, e.inspect
        else
          @client.log TRACE, "upstream service closed stream #{@id}"
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

