
module Envoy
  module Server
    
    class Channel
      
      attr_accessor :trunk, :web
      
      def initialize trunk, web, header
        @trunk = trunk
        @web = web
        @trunk.channels[id] = self
        @trunk.send_object :connection, id
        stream header
      end
      
      def stream data
        @trunk.send_object :stream, id, data
      end
      
      def id
        @id ||= SecureRandom.hex(4)
      end
      
    end
    
  end
end

