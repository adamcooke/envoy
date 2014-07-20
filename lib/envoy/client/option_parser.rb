require 'optparse'

def default_options
  {
    "server_host" => 'p45.eu',
    "server_port" => "8282",
    "local_host" => '127.0.0.1',
    "tls" => false,
    "verbosity" => 3,
    "version" => Envoy::VERSION,
    "delay" => 1,
    "dir" => ".",
    "timestamps" => false,
    "show_log_level" => true,
    "color_log_level" => true,
  }
end

def parse_options
  options = default_options
  OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [[HOST:]PORT] [LABEL]"
    op.on "-l LABEL", "--label", "--host", "Allocate this domain label on the proxy" do |v|
      options["hosts"] ||= []
      options["hosts"] << v
    end
    op.on "-k KEY", "--key", "Secure access to the label with this key" do |v|
      options["key"] = v
    end
    op.on "-s SERVER", "--server", "Specify envoy server" do |v|
      host, port = v.split(":")
      options["server_host"] = host
      options["server_port"] ||= port
    end
    op.on "-c COMMAND", "Run this command" do |v|
      options["command"] = v
    end
    op.on "-v", "--verbose", "Show messages. Repeat to show more." do
      options["verbosity"] += 1
    end
    op.on "-q", "--quiet", "Hide messages. Repeat to hide more." do
      options["verbosity"] -= 1
    end
    op.on "-h", "--help", "Show this message" do
      puts op
      exit
    end
    op.on "-V", "--version", "Show version number" do
      puts Envoy::VERSION
      exit
    end
    op.parse!
    case ARGV[0]
    when "rails"
      options["pidfile"] = "tmp/pids/server.pid"
      options["command"] = "rails s -p %{local_port}"
      options["delay"] = 10
    when "rackup"
      options["command"] = "rackup -p %{local_port}"
      options["delay"] = 10
    when /^(\d+)$/
      options["local_port"] = $1
    when /^(\[[^\]+]\]|[^:]+):(\d+)$/x
      options["local_host"] = $1
      options["local_port"] = $2
    when /^(.*)$/
      options["local_host"] = $1
    end
    if ARGV[1]
      options["hosts"] ||= []
      options["hosts"] << ARGV[1]
    end
  end
  options
end

