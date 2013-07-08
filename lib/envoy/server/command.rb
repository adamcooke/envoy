require 'envoy/server/trunk'
require 'envoy/server/web'
require 'optparse'

listen = ["0.0.0.0", "8080"]
key = nil

OptionParser.new do |op|
  op.banner = "Usage: #{$0} [options] ZONE"
  op.on "-l", "--listen ADDRESS", "Listen on this [host:]port for HTTP" do |v|
    port, host = v.split(":").reverse
    listen = [host || "0.0.0", port]
  end
  op.on "-k", "--key KEY", "Require authentication using KEY" do |v|
    key = v
  end
  op.on "--version" do
    puts Envoy::VERSION
    exit
  end
  op.parse!
  op.abort "zone required" unless ARGV[0]
end

$zone = ARGV[0].gsub(/^\.+/, '')

unless EM.reactor_running?
  EM.run do
    EM.start_server "0.0.0.0", 8282, Envoy::Server::Trunk, key
    EM.start_server *listen, Envoy::Server::Web
  end
end