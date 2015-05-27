require 'simplecov'
SimpleCov.command_name 'tef-core-rspec'


require_relative '../../../spec/common/specs/configured_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_integration_specs'
require_relative '../../../spec/common/specs/service_component_unit_specs'
require_relative '../../../spec/common/specs/service_component_integration_specs'


require 'tef/core'


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
