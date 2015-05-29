# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tef/worker/version'

Gem::Specification.new do |spec|
  spec.name          = 'tef-worker'
  spec.version       = TEF::Worker::VERSION
  spec.authors       = ['Donavan Stanley', 'Eric Kessler']
  spec.email         = ['stanleyd@grangeinsurance.com']
  spec.summary       = %q{The task working portion of the TEF}
  spec.description   = %q{A basic task worker.}
  spec.homepage      = 'https://github.com/orgs/grange-insurance'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'cucumber', '~> 2.0'
  spec.add_development_dependency 'bundler' , '~> 1.6'
  spec.add_development_dependency 'rake'    , '~> 10.3'
  spec.add_development_dependency 'rspec'   , '~> 3.0'
  spec.add_development_dependency 'rspec-mocks', '~> 3.0'
  spec.add_development_dependency 'rspec-wait', '= 0.0.2'
  spec.add_development_dependency 'simplecov', '~> 0.9'

  spec.add_dependency 'bunny', '~> 1.4'
  spec.add_dependency 'workers', '~> 0.3'
  spec.add_dependency 'task_runner', '~> 0'
  spec.add_dependency 'tef-core', '~> 0'
  spec.add_dependency 'process', '~> 0.0'
end
