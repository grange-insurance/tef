# todo - Have to redo all of this now that the Cucumber portion of the TEF is a separate project
require 'simplecov'
SimpleCov.command_name 'tef-cucumber'

# require 'cucumber/rspec/doubles'
# require 'bunny'
# # Used for #wait_for
# require 'rspec/wait'
# include RSpec::Wait

# # Used to conveniently get process ids for test cleanup
# require 'sys/proctable'
# include Sys
#
# require 'open3'
#
# require 'tef'
# require_relative '../../testing/fakes'
# World(TefTestingFakes)
#
#
# ENV['TEF_ENV'] ||= 'dev'
# ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'
# ENV['TEF_QUEUEBERT_SEARCH_ROOT'] ||= "#{File.dirname(__FILE__)}/../../testing"
# ENV['TEF_WORK_NODE_ROOT_LOCATION'] ||= "#{File.dirname(__FILE__)}/../../testing"
#
# # TEF::CukeKeeper::init_db
#
# # RSpec::Wait::Handler.set_wait_timeout(30)
# RSpec.configure do |config|
#   config.wait_timeout = 30
# end
#
# require 'database_cleaner'
# DatabaseCleaner.strategy = :truncation, {only: %w(keeper_dev_features keeper_dev_scenarios keeper_dev_test_suites tef_dev_tasks tef_dev_task_resources)}
# DatabaseCleaner.start
# DatabaseCleaner.clean
#
#
# Before do
#   begin
#     @tef_env = ENV['TEF_ENV'].downcase
#     @bunny_url = ENV["TEF_AMQP_URL_#{@tef_env}"]
#
#
#     @base_request = {
#         'name' => 'TEF test cucumber suite request',
#         'dependencies' => '',
#     }
#
#     @test_search_root = "#{File.dirname(__FILE__)}/../../testing"
#
#     @bunny_connection = Bunny.new(@bunny_url)
#     @bunny_connection.start
#     @bunny_channel = @bunny_connection.create_channel
#   rescue => e
#     puts "caught before exception: #{e.message}"
#     puts "trace: #{e.backtrace}"
#     raise e
#   end
# end
#
#
# Before do
#   begin
#     stdout, stderr, status = Open3.capture3('rabbitmqctl list_queues name')
#     queue_list = stdout.split("\n").slice(1..-2)
#
#     queue_list.each { |queue| delete_queue(queue) }
#   rescue => e
#     puts "Problem caught in Before hook: #{e.message}"
#   end
# end
#
# After do
#   kill_existing_tef_processes
#   DatabaseCleaner.clean
# end
#
# def get_queue(queue_name)
#   @bunny_channel.queue(queue_name, passive: true)
# end
#
# def delete_queue(queue_name)
#   @bunny_connection.create_channel.queue_delete(queue_name)
# end
#

