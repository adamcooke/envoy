require 'optparse'

def default_options
  {
    "server_host" => 'p45.eu',
    "server_port" => "8282",
    "local_host" => '127.0.0.1',
    "tls" => false,
    "verbose" => false,
    "version" => Envoy::VERSION,
    "delay" => 1,
    "dir" => "."
  }
end

def parse_options
  options = default_options
  OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [[HOST:]PORT]"
    op.on "--host HOST", "Allocate this domain label on the proxy" do |v|
      options["hosts"] ||= []
      options["hosts"] << v
    end
    op.on "-k", "--key KEY" do |v|
      options["key"] = v
    end
    op.on "-t", "--[no-]tls", "Encrypt communications with the envoy server" do |v|
      options["tls"] = v
    end
    op.on "-s", "--server SERVER", "Specify envoy/proxylocal server" do |v|
      host, port = v.split(":")
      options["server_host"] = host
      options["server_port"] ||= port
    end
    op.on "-v", "--[no-]verbose", "Be noisy about what's happening" do |v|
      options["verbose"] = v
    end
    op.on "-h", "--help", "Show this message" do
      puts op
      exit
    end
    op.on "--version" do
      puts Envoy::VERSION
      exit
    end
    op.parse!
    case ARGV[0]
    when /^(\d+)$/
      options["local_port"] = $1
    when /^(\[[^\]+]\]|[^:]+):(\d+)$/x
      options["local_host"] = $1
      options["local_port"] = $2
    when /^(.*)$/
      options["local_host"] = $1
    end
  end
  options
end

