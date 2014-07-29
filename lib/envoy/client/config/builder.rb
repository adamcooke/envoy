class Envoy::Client::Config; end

class Envoy::Client::Config::Builder

  def initialize (config)
    @config = config
  end

  def run (path)
    instance_eval(File.read(path), path)
  end

  def set (name, value)
    @config.__send__("#{name}=", value)
  end

  def fetch (name, &block)
    if r = @config.__send__(name)
      r
    elsif block
      set(name, block.())
    end
  end

  def export (type, *args)
    case type
    when :tcp
      args = args[0].split(":") if args[0] and !args[1]
      args[0] ||= "127.0.0.1"
      args[1] ||= rand(16383) + 49152
      args = [:tcp, *args]
    when :unix
      args[0] ||= ".envoy.sock"
      args = [:unix, *args]
    end
    set :export, args
  end

  def localsock ()
    export(:unix)[1]
  end

  def localhost
    export(:tcp)[1]
  end

  def localport ()
    export(:tcp)[2]
  end

end
