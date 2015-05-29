require 'simplecov'
SimpleCov.command_name 'tef-worker-rspec'


require 'bunny'

require_relative '../../../spec/common/specs/configured_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_integration_specs'
require_relative '../../../spec/common/specs/receiving_component_integration_specs'
require_relative '../../../spec/common/specs/receiving_component_unit_specs'
require_relative '../../../spec/common/specs/sending_component_integration_specs'
require_relative '../../../spec/common/specs/sending_component_unit_specs'
require_relative '../../../spec/common/specs/worker_component_unit_specs'
require_relative '../../../spec/common/specs/worker_component_integration_specs'
require_relative '../../../spec/common/specs/service_component_unit_specs'
require_relative '../../../spec/common/specs/service_component_integration_specs'
require_relative '../../../spec/common/specs/rooted_component_unit_specs'
require_relative '../../../spec/common/specs/rooted_component_integration_specs'

require_relative '../../../testing/fakes'
include TefTestingFakes
require_relative '../../../testing/mocks'
include TefTestingMocks

require 'tef/worker'


RSpec.configure do |config|
  config.before(:all) do
    ENV['TEF_ENV'] ||= 'dev'
    ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'

    @default_file_directory = "#{File.dirname(__FILE__)}/../temp_files"
  end

  config.before(:each) do
    FileUtils.mkdir(@default_file_directory)
  end

  config.after(:each) do
    FileUtils.remove_dir(@default_file_directory, true)
  end

end

# This seems like something that Bunny should already have...
def get_queue(queue_name)
  @bunny_connection.create_channel.queue(queue_name, passive: true)
end
