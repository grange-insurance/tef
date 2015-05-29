require 'simplecov'
SimpleCov.command_name 'tef-keeper-rspec'


require 'tef/keeper'

require_relative '../../../spec/common/specs/configured_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_integration_specs'
require_relative '../../../spec/common/specs/receiving_component_integration_specs'
require_relative '../../../spec/common/specs/receiving_component_unit_specs'
require_relative '../../../spec/common/specs/sending_component_integration_specs'
require_relative '../../../spec/common/specs/sending_component_unit_specs'
require_relative '../../../spec/common/specs/service_component_unit_specs'
require_relative '../../../spec/common/specs/service_component_integration_specs'

require_relative '../../../testing/fakes'
include TefTestingFakes
require_relative '../../../testing/mocks'
include TefTestingMocks


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
