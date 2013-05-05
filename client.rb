require 'eventmachine'
require 'securerandom'
require 'logger'
require 'bert'
require 'rack'

require './protocol.rb'

$reloader = Rack::Reloader.new(proc{}, 0)
$logger = Logger.new(STDERR)

options = {
  server_host: '127.0.0.1',
  server_port: 8282,
  local_port: 80,
  tls: false,
  verbose: false,
  hosts: []
}

options[:hosts] = ["test"]
options[:local_host] = "p12a.org.uk"

module Channel
  
  def initialize id, trunk
    @id, @trunk = id, trunk
    super()
  end
  
  def receive_data data
    @trunk.send_object :stream, @id, data
  end
  
  def unbind
    @trunk.send_object :close, @id
  end
  
end

module Client
  include Protocol
  
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
  
  attr_reader :options
  
  def initialize options
    @options = options
  end
  
  def channels
    @channels ||= {}
  end
  
  def receive_start_tls
    start_tls
  end
  
  def receive_stream id, data
    channels[id].send_data data
  end
  
  def receive_connection id
    channels[id] = EM.connect(options[:local_host] || '127.0.0.1',
                              options[:local_port], Channel, id, self)
  end
  
  def receive_message message
    $logger.info message
  end
  
  def receive_halt
    EventMachine.stop_event_loop
  end
  
  def unbind
    EM.stop_event_loop
  end
  
  def ssl_handshake_completed
    send_object :options, options
  end
  
  def post_init
    send_object :start_tls
  end
  
end

Client.run options

