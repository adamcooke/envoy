require 'eventmachine'
require 'bert'

module Envoy

  module Protocol
    include EM::P::ObjectProtocol
    
    module Serializer
      def self.dump(object)
        BERT.encode(object)
      end
      def self.load(data)
        BERT.decode(data)
      end
    end
    
    def serializer
      Serializer
    end
    
    def send_object *args
      super(args.size > 1 ? BERT::Tuple[*args] : args[0])
    end
    
    def receive_object ((command, *args))
      __send__("receive_#{command}", *args)
    end
    
  end

end
