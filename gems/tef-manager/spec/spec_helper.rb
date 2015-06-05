require 'simplecov'
SimpleCov.command_name 'tef-manager-rspec'

require 'tef/development/specs/configured_component_unit_specs'
require 'tef/development/specs/logged_component_unit_specs'
require 'tef/development/specs/logged_component_integration_specs'
require 'tef/development/specs/service_component_unit_specs'
require 'tef/development/specs/service_component_integration_specs'
require 'tef/development/specs/receiving_component_integration_specs'
require 'tef/development/specs/receiving_component_unit_specs'
require 'tef/development/specs/message_controlled_component_specs'


require 'tef/development/testing/mocks'
include TEF::Development::Testing::Mocks
require 'tef/development/testing/fakes'
include TEF::Development::Testing::Fakes

require_relative 'fakes'
require_relative 'mocks'


require 'tef/manager'


def tef_env
  !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
end

def tef_config
  !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : './config'
end


RSpec.configure do |config|

  config.before(:all) do
    ENV['TEF_ENV'] ||= 'dev'
    ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'
  end

#   config.before(:each) do
#     # Nothing yet
#   end

#   config.after(:each) do
#     # Nothing yet
#   end

end
