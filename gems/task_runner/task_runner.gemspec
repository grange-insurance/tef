# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'task_runner/version'

Gem::Specification.new do |spec|
  spec.name          = "task_runner"
  spec.version       = TaskRunner::VERSION
  spec.authors       = ['Donavan Stanley', 'Eric Kessler']
  spec.email         = ['donavan.stanley@gmail.com', 'morrow748@gmail.com']
  spec.summary       = %q{A gem to handle running tasks.}
  spec.description   = %q{A gem to handle running tasks within the TEF}
  spec.homepage      = "https://github.com/orgs/grange-insurance"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "rspec", '~> 3.0'
  spec.add_development_dependency "simplecov", '~> 0.9'
end
