require 'simplecov'
SimpleCov.command_name 'tef-keeper-rspec'


require 'tef/keeper'

require 'tef/development/specs/configured_component_unit_specs'
require 'tef/development/specs/logged_component_unit_specs'
require 'tef/development/specs/logged_component_integration_specs'
require 'tef/development/specs/receiving_component_integration_specs'
require 'tef/development/specs/receiving_component_unit_specs'
require 'tef/development/specs/sending_component_integration_specs'
require 'tef/development/specs/sending_component_unit_specs'
require 'tef/development/specs/service_component_unit_specs'
require 'tef/development/specs/service_component_integration_specs'
require 'tef/development/specs/wrapper_component_integration_specs'
require 'tef/development/specs/wrapper_component_unit_specs'


require 'tef/development/testing/fakes'
include TEF::Development::Testing::Fakes
require 'tef/development/testing/mocks'
include TEF::Development::Testing::Mocks


RSpec.configure do |config|
  config.before(:all) do

    ENV['TEF_ENV'] ||= 'dev'
    ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'
  end

  config.before(:each) do
  end

  config.after(:each) do
  end

end
