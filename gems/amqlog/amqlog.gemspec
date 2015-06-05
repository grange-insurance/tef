# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'amqlog/version'

Gem::Specification.new do |gem|
  gem.name          = "amqlog"
  gem.version       = Amqlog::VERSION
  gem.authors       = ['Donavan Stanley', 'Eric Kessler']
  gem.email         = ['donavan.stanley@gmail.com', 'morrow748@gmail.com']
  gem.description   = %q{A Logger device that outputs to RabbitMQ.}
  gem.summary       = %q{Log rabbit log.}
  gem.homepage      = 'https://github.com/orgs/grange-insurance'
  gem.license       = 'MIT'
  

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency 'rake', '~> 10.3'
  gem.add_development_dependency 'rspec', '~> 2.14'
  gem.add_development_dependency 'simplecov', '~> 0.9'

  gem.add_dependency 'amqp', '~> 1.5'
end
