require 'simplecov'
SimpleCov.command_name 'tef-keeper-cucumber'

require 'open3'
require 'cucumber/rspec/doubles'
# Used for #wait_for
require 'rspec/wait'
World(RSpec::Wait)

require 'tef/keeper'
#require_relative '../../spec/fake_publisher'

# Common testing code
require 'tef/development'
World(TEF::Development)


ENV['TEF_ENV'] ||= 'dev'
ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'

Before do
  begin
    @test_result = {
        guid: '12345'
    }

    @test_callback = double('callback')
    allow(@test_callback).to receive(:call)

    @tef_env = ENV['TEF_ENV'].downcase
    @bunny_url = ENV["TEF_AMQP_URL_#{@tef_env}"]

    @bunny_connection = Bunny.new(@bunny_url)
    @bunny_connection.start
    @bunny_channel = @bunny_connection.create_channel
  rescue => e
    puts "Problem caught in Before hook: #{e.message}"
  end
end

Before do
  begin
    stdout, stderr, status = Open3.capture3('rabbitmqctl list_queues name')
    queue_list = stdout.split("\n").slice(1..-2)

    queue_list.each { |queue| delete_queue(queue) }
  rescue => e
    puts "Problem caught in Before hook: #{e.message}"
  end
end

After do
  # Nothing yet...
end

def empty_queue(queue)
  queue.message_count.times do
    queue.pop
  end
end
