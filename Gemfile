source 'https://rubygems.org'
source 'https://gems.github.com'


# The gems that we use to test our stuff
def testing_gems
  gem 'rake'
  gem 'rspec', '~> 3.0.0'
  gem 'rspec-wait'
  gem 'cucumber'
  gem 'simplecov'
  gem 'bundler', '~> 1.6'
  gem 'bunny', '~> 1.4'
  gem 'database_cleaner'
  gem 'racatt'
  gem 'codacy-coverage', :require => false
end

# The development (i.e. source code) versions of gems that are (or are needed by) our stuff
def dev_gems

  # Dev mode has to explicitly include every needed gem dependency in the project in order to
  # be properly (i.e. recursively) loaded from source by Bundler
  gem 'task_runner', :path => 'gems/task_runner'
  gem 'tef-worker', :path => 'gems/tef-worker'
  gem 'tef-core', :path => 'gems/tef-core'
  gem 'res_man', git: 'https://github.com/grange-insurance/res_man.git', branch: 'master'
  gem 'tef-manager', :path => 'gems/tef-manager'
  gem 'tef-keeper', :path => 'gems/tef-keeper'
  gem 'tef', :path => '.'
  gem 'tef-development', :path => 'gems/tef-development'
end

# The real (i.e. installed on the machine) versions gems that are (or are needed by) our stuff
def test_gems
  gem 'tef-worker'
  gem 'tef-manager'
  gem 'tef-keeper'
  gem 'tef'
  gem 'tef-development'
end

# Nothing new to see here.
def prod_gems
  test_gems
end

mode = ENV['BUNDLE_MODE'] || 'dev'
puts "Bundler mode: #{mode}"

case mode
  when 'dev'
    testing_gems
    dev_gems
  when 'test', 'prod'
    testing_gems
    test_gems
  when 'prod'
    prod_gems
  else
    raise(ArgumentError, "Unknown bundle mode: #{mode}. Must be one of dev/test/prod.")
end
