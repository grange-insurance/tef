require 'simplecov'
SimpleCov.command_name 'task_runner-rspec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))


require 'task_runner'


require_relative '../../../spec/common/specs/configured_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_integration_specs'
require_relative '../../../testing/mocks'

include TefTestingMocks


RSpec.configure do |config|
  config.before(:all) do
    @default_file_directory = "#{File.dirname(__FILE__)}/temp_files"
    @default_test_file_directory = "#{File.dirname(__FILE__)}/test_data"
  end

  config.before(:each) do
    FileUtils.mkpath(@default_file_directory)
  end

  config.after(:each) do
    FileUtils.remove_dir(@default_file_directory, true)
  end

end
