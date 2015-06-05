require 'simplecov'
SimpleCov.command_name 'tef-worker-rspec'


require 'bunny'

require 'tef/development/specs/configured_component_unit_specs'
require 'tef/development/specs/logged_component_unit_specs'
require 'tef/development/specs/logged_component_integration_specs'
require 'tef/development/specs/receiving_component_integration_specs'
require 'tef/development/specs/receiving_component_unit_specs'
require 'tef/development/specs/sending_component_integration_specs'
require 'tef/development/specs/sending_component_unit_specs'
require 'tef/development/specs/worker_component_unit_specs'
require 'tef/development/specs/worker_component_integration_specs'
require 'tef/development/specs/service_component_unit_specs'
require 'tef/development/specs/service_component_integration_specs'
require 'tef/development/specs/rooted_component_unit_specs'
require 'tef/development/specs/rooted_component_integration_specs'


require 'tef/development/testing/fakes'
include TEF::Development::Testing::Fakes
require 'tef/development/testing/mocks'
include TEF::Development::Testing::Mocks

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
