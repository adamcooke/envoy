
module Envoy
  
  module Client
    
    module Channel
      
      def initialize id, client
        @id, @client = id, client
        @buffer = ""
        super()
      end
      
      def connection_completed
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
        @client.send_object :stream, @id, data
      end
      
      def reconnect
        super @client.options[:local_host], @client.options[:local_port]
      end
      
      def unbind e
        if e == Errno::ECONNREFUSED
          if @tried_starting
            @client.log "Service isn't running, but starting it didn't really work out."
            @client.send_object :close, @id, 502
          elsif cmd = @client.options[:command]
            cmd = cmd % @client.options
            @client.log "Service doesn't seem to be running. Trying to start it now..."
            @tried_starting = true
            Dir.chdir File.expand_path(@client.options[:dir]) do
              fork do
                #Process.daemon(true, false)
                ENV.delete("GEM_HOME")
                ENV.delete("GEM_PATH")
                ENV.delete("BUNDLE_BIN_PATH")
                ENV.delete("BUNDLE_GEMFILE")
                system cmd
              end
            end
            EM.add_timer @client.options[:delay] do
              reconnect
            end
          end
        elsif e
          @client.log e.inspect
        else
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

