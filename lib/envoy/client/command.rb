require 'envoy/client/trunk'
require 'envoy/client/option_parser'
require 'envoy/version'
require 'yaml'

def find_config
  dirs = Dir.pwd.split("/")
  r = dirs.reduce([]) do |m, x|
    [[*m[0], x], *m]
  end.map do |p|
    p.join("/") + "/.envoy"
  end.each do |p|
    return p if File.exist?(p)
  end
  false
end

def load_config
  conf = YAML.load(File.read(find_config))
  conf.is_a?(Array) ? conf : [conf]
end

options = parse_options

unless EM.reactor_running?
  EM.run do
    load_config.each do |config|
      config["local_port"] ||= rand(16383) + 49152
      config = options.merge(config)
      config["hosts"] ||= [config.delete("host")]
      config = config.each_with_object({}) do |(k, v), h|
        h[k.to_sym] = v
      end
      Envoy::Client::Trunk.start p config
    end
  end
end

