require 'simplecov'
SimpleCov.command_name 'tef-core-rspec'


require 'tef/development/specs/configured_component_unit_specs'
require 'tef/development/specs/logged_component_unit_specs'
require 'tef/development/specs/logged_component_integration_specs'
require 'tef/development/specs/service_component_unit_specs'
require 'tef/development/specs/service_component_integration_specs'
require 'tef/development/specs/wrapper_component_unit_specs'
require 'tef/development/specs/wrapper_component_integration_specs'


RSpec.configure do |config|
  config.before(:all) do
    ENV['TEF_ENV'] ||= 'dev'
    ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'
  end

  config.before(:each) do
    # Nothing yet
  end

  config.after(:each) do
    # Nothing yet
  end

end
