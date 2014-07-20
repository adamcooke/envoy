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
  if path = find_config
    conf = YAML.load(File.read(path))
    Array(conf).each do |conf|
      if conf["rails"]
        conf["dir"] = conf["rails"]
        conf["pidfile"] = "tmp/pids/server.pid"
        conf["command"] = "rails s -p %{local_port}"
        conf["delay"] = 10
      elsif conf["rackup"]
        conf["dir"] = conf["rackup"]
        conf["command"] = "rackup -p %{local_port}"
        conf["delay"] = 10
      end
      conf["host"] ||= conf["dir"].split("/")[-1] if conf["dir"]
      conf["dir"] = File.expand_path(conf["dir"], path + "/..") if conf["dir"]
    end
  else
    [{}]
  end
end

options = parse_options

unless EM.reactor_running?
  EM.run do
    Signal.trap("INT") do
      $exiting = true
      EventMachine.stop
    end
    Signal.trap("TERM") do
      $exiting = true
      EventMachine.stop
    end
    load_config.each do |config|
      config = config.merge(options)
      config["local_port"] ||= config["command"] ? rand(16383) + 49152 : 80
      config["hosts"] ||= [config.delete("host")] if config["host"]
      config = config.each_with_object({}) do |(k, v), h|
        h[k.to_sym] = v
      end
      Envoy::Client::Trunk.start config
    end
  end
end
