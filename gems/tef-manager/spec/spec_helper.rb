require 'simplecov'
SimpleCov.command_name 'tef-manager-rspec'

require_relative '../../../spec/common/specs/configured_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_integration_specs'
require_relative '../../../spec/common/specs/service_component_unit_specs'
require_relative '../../../spec/common/specs/service_component_integration_specs'
require_relative '../../../spec/common/specs/receiving_component_integration_specs'
require_relative '../../../spec/common/specs/receiving_component_unit_specs'
require_relative '../../../spec/common/specs/message_controlled_component_specs'

require_relative '../../../testing/mocks'
include TefTestingMocks
require_relative '../../../testing/fakes'
include TefTestingFakes

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
