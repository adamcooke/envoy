# coding: utf-8
# -*- encoding: utf-8; mode: ruby -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'envoy/version'

Gem::Specification.new do |spec|
  spec.name          = "envoy-proxy"
  spec.version       = Envoy::VERSION
  spec.authors       = ["Nathan Baum"]
  spec.email         = ["n@p12a.org.uk"]
  spec.summary       = %q{Proxy your local web-server and make it publicly available over the internet}
  spec.homepage      = ""
  spec.license       = "AGPL3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_dependency('eventmachine', '>= 1.0.3')
  spec.add_dependency('bert', '>= 1.1.6')
  
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
