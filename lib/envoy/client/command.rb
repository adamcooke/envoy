require 'envoy/client/trunk'
require 'envoy/client/config'
require 'envoy/version'

class Envoy::Client::Command

  def run (args)
    EM.run do
      Envoy.verbosity = Envoy::INFO
      stopper = proc { $exiting = true; EventMachine.stop }
      Signal.trap("INT", stopper)
      Signal.trap("TERM", stopper)
      Envoy.log(Envoy::DEBUG, "envoy #{Envoy::VERSION} starting up")
      config = Envoy::Client::Config.new
      config.parse_options
      config.parse_envoyfile
      config.infer_sane_defaults
      config.start_service
      Envoy::Client::Trunk.start config
    end
  end

end
