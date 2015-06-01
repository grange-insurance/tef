# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tef/version'

Gem::Specification.new do |spec|
  spec.name          = 'tef'
  spec.version       = TEF::VERSION
  spec.authors       = ['Donavan Stanley', 'Eric Kessler']
  spec.email         = ['stanleyd@grangeinsurance.com']
  spec.summary       = %q{A super awesome gem}
  spec.description   = %q{It deals with tasks.}
  spec.homepage      = 'https://github.com/orgs/grange-insurance'
  spec.license       = 'MIT'

  # Should figure out some kind of documentation to include as the gems files?
  #spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.add_development_dependency 'cucumber', '~> 2.0'
  spec.add_development_dependency 'bundler' , '~> 1.6'
  spec.add_development_dependency 'rake'    , '~> 10.3'
  spec.add_development_dependency 'rspec'   , '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.9'

  spec.add_dependency 'tef-worker', '~> 0'
  spec.add_dependency 'tef-manager', '~> 0'
  spec.add_dependency 'tef-keeper', '~> 0'
end
