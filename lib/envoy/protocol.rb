require 'eventmachine'
require 'bert'

TRACE = 5
DEBUG = 4
INFO  = 3
WARN  = 2
ERROR = 1
FATAL = 0

module Envoy

  module Protocol
    include EM::P::ObjectProtocol
    
    VERBOSITIES = %w"FATAL ERROR WARN\  INFO\  DEBUG TRACE"
    
    def verbosity
      @verbosity ||= [FATAL, [TRACE, @options[:verbosity] || 3].min].max
    end
      
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
