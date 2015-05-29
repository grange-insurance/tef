require 'simplecov'
SimpleCov.command_name 'tef-worker-cucumber'

require 'bunny'
require 'socket'
# Used for #wait_for
require 'rspec/wait'
include RSpec::Wait

# require 'cucumber/rspec/doubles'
# require_relative '../../spec/fake_publisher'

require 'tef/worker'


ENV['TEF_ENV'] ||= 'dev'
ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'


Before do
  begin
    @tef_env = ENV['TEF_ENV'].downcase
    @bunny_url = ENV["TEF_AMQP_URL_#{@tef_env}"]

    @default_worker_queue_name = "test_worker.#{Socket.gethostname}"
    @default_keeper_queue_name = "test_keeper.temp"


    @default_file_directory = "#{File.dirname(__FILE__)}/../temp_files"

    @test_task = {
        type: "task",
        task_type: "echo",
        guid: "12345",
        priority: 1,
        resources: "foo",
        time_limit: 10,
        suite_guid: "67890",
        task_data: {command: "echo 'Hello'"},
        root_location: @default_file_directory
    }


    @bunny_connection = Bunny.new(@bunny_url)
    @bunny_connection.start
      #@default_file_directory = "#{File.dirname(__FILE__)}/../temp_files"
  rescue => e
    puts "caught a problem in a before hook: #{e.message}"
  end

end

Before('~@unit') do
  stdout, stderr, status = Open3.capture3('rabbitmqctl list_queues name')
  queue_list = stdout.split("\n").slice(1..-2)

  queue_list.each { |queue| delete_queue(queue) }

  FileUtils.remove_dir(@default_file_directory, true) if Dir.exists?(@default_file_directory)
  FileUtils.mkdir(@default_file_directory)
end

After('~@unit') do
  FileUtils.remove_dir(@default_file_directory, true)
end

After do
  # No dangling timer threads please
  @worker.stop if @worker
end

# def process_path(path)
#  path.sub('path/to', @default_file_directory)
# end

# Getting a little wet here...
def get_queue(queue_name)
  @bunny_connection.create_channel.queue(queue_name, passive: true)
end

def delete_queue(queue_name)
  @bunny_connection.create_channel.queue_delete(queue_name)
end

def empty_queue(queue)
  queue.message_count.times do
    queue.pop
  end
end
