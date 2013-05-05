
module Envoy
  module Client
    
    module Channel
      
      def initialize id, client
        @id, @client = id, client
        super()
      end
      
      def receive_data data
        @client.send_object :stream, @id, data
      end
      
      def unbind
        @client.send_object :close, @id
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

