require_relative '../../../../features/step_definitions/common/action_steps'


When(/^a worker is created$/) do
  options = {}
  options[:name] = @worker_name if @worker_name

  @worker = TEF::Worker::WorkNode.new(options)
end

When(/^a worker is started$/) do
  options = {}
  options[:root_location] = @default_file_directory
  options[:worker_type] = @worker_type if @worker_type
  options[:queue_prefix] = @prefix if @prefix
  options[:in_queue] = @worker_queue_name if @worker_queue_name
  options[:out_queue] = @keeper_queue_name if @keeper_queue_name
  options[:manager_queue] = @manager_queue_name if @manager_queue_name

  @worker = TEF::Worker::WorkNode.new(options)
  @worker.start
end

When(/^it is given a task to work$/) do
  @test_task[:guid] = '112233'

  get_queue(@worker.in_queue_name).publish(@test_task.to_json)
end
