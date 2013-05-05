require 'envoy/server/trunk'
require 'envoy/server/web'

unless ARGV[0]
  puts "Usage: #{$0} [ZONE]"
  abort
end

$zone = ARGV[0]

unless EM.reactor_running?
  EM.run do
    EM.start_server "0.0.0.0", 8282, Envoy::Server::Trunk
    EM.start_server "0.0.0.0", 8181, Envoy::Server::Web
  end
end

