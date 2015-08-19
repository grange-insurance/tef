# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tef/development/version'

Gem::Specification.new do |spec|
  spec.name          = "tef-development"
  spec.version       = TEF::Development::VERSION
  spec.authors       = ["Eric Kessler"]
  spec.email         = ["morrow748@gmail.com"]

  spec.summary       = %q{A gem providing common code useful in the development of TEF components.}
  spec.homepage      = 'https://github.com/grange-insurance/tef/tree/master/gems/tef-development'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'sys-proctable'
  spec.add_dependency 'activerecord'

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
