# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'droplet_ctl/version'

Gem::Specification.new do |spec|
  spec.name          = 'droplet_ctl'
  spec.version       = DropletCtl::VERSION
  spec.authors       = ['Joakim Reinert']
  spec.email         = ['mail@jreinert.com']

  spec.summary       = 'A command line utility for a few digitalocean API tasks'
  spec.homepage      = 'https://git.jreinert.com/jreinert/droplet_ctl'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)\/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
end
