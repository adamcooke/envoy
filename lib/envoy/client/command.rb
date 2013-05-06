require 'envoy/client/trunk'

require 'optparse'
require 'ostruct'

options = {
  server_host: 'p45.eu',
  server_port: "8282",
  local_host: '127.0.0.1',
  local_port: "80",
  tls: false,
  verbose: false,
  version: Envoy::VERSION
}

OptionParser.new do |op|
  op.banner = "Usage: #{$0} [options] [[HOST:]PORT]"
  op.on "--host HOST", "Allocate this domain label on the proxy" do |v|
    options[:hosts] ||= []
    options[:hosts] << v
  end
  op.on "-t", "--[no-]tls", "Encrypt communications with the envoy server" do |v|
    options[:tls] = v
  end
  op.on "-s", "--server SERVER", "Specify envoy/proxylocal server" do |v|
    host, port = v.split(":")
    options[:server_host] = host
    options[:server_port] ||= port
  end
  op.on "-v", "--[no-]verbose", "Be noisy about what's happening" do |v|
    options[:verbose] = v
  end
  op.on "-h", "--help", "Show this message" do
    puts op
    exit
  end
  op.parse!
  case ARGV[0]
  when /^(\d+)$/
    options[:local_port] = $1
  when /^(\[[^\]+]\]|[^:]+):(\d+)$/x
    options[:local_host] = $1
    options[:local_port] = $2
  when /^(.*)$/
    options[:local_host] = $1
  end
end

unless EM.reactor_running?
  EM.run do
    EM.connect options[:server_host], options[:server_port].to_i, Envoy::Client::Trunk, options
  end
end

