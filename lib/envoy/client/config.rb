require 'envoy/client/config/builder'
require 'envoy/utils'
require 'optparse'

class Envoy::Client::Config

  attr_accessor :server
  attr_accessor :key
  attr_accessor :label
  attr_accessor :command
  attr_accessor :export

  def initialize
    @server = ["p45.eu", 8282]
    @key = ENV["ENVOY_KEY"] || SecureRandom.base64(8)
  end

  def options
    {
      hosts: [label].compact,
      key: key,
      verbosity: true,
      version: Envoy::VERSION
    }
  end

  def start_service
    return unless command
    Envoy.log Envoy::INFO, "Starting service..."
    fork do
      ENV.delete("GEM_HOME")
      ENV.delete("GEM_PATH")
      ENV.delete("BUNDLE_BIN_PATH")
      ENV.delete("BUNDLE_GEMFILE")
      system(command)
    end
  end

  def infer_sane_defaults
    self.export = [:tcp, "127.0.0.1", 80] unless export
  end

  def parse_envoyfile
    if path = Envoy.find_file("Envoyfile")
      Builder.new(self).run(path)
    end
  end

  def parse_options
    OptionParser.new do |op|
      op.banner = "Usage: #{$0} [options]"
      op.on "-l LABEL", "Use this domain label" do |lab|
        @label = lab
      end
      op.on "-d DIRECTORY", "Change to this directory before starting envoy" do |dir|
        Dir.chdir(dir)
      end
      op.on "-k KEY", "Secure access to the label with this key" do |v|
        @key = v
      end
      op.on "-s SERVER", "Specify envoy server" do |v|
        host, port = v.split(":")
        @server = [host, port || @server[1]]
      end
      op.on "-v", "Show messages. Repeat to show more." do
        Envoy.verbosity += 1
      end
      op.on "-q", "Hide messages. Repeat to hide more." do
        Envoy.verbosity -= 1
      end
      op.on "-h", "Show this message" do
        puts op
        exit
      end
      op.on "-V", "Show version number" do
        puts Envoy::VERSION
        exit
      end
      op.parse!
      case ARGV[0]
      when nil
      when /\//
        @export = [:unix, ARGV[0]]
      when /^([^:]+):(\d+)$/
        @export = [:tcp, $1 || "127.0.0.1", $2]
      when /^(\d+)$/
        @export = [:tcp, "127.0.0.1", $1]
      else
        @export = [:tcp, ARGV[0], 80]
      end
    end
  end

end
