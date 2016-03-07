require 'tef/development/step_definitions/action_steps'


When(/^a worker is created$/) do
  options = {}
  options[:name] = @worker_name if @worker_name

  @worker = TEF::Worker::WorkNode.new(options)
end

When(/^a worker is started$/) do
  options = {}
  options[:root_location] = @default_file_directory
  options[:worker_type] = @worker_type if @worker_type
  options[:name_prefix] = @prefix if @prefix
  options[:in_queue] = @worker_queue_name if @worker_queue_name
  options[:output_exchange] = @output_exchange_name if @output_exchange_name
  options[:manager_queue] = @manager_queue_name if @manager_queue_name

  @worker = TEF::Worker::WorkNode.new(options)
  @worker.start
end

When(/^it is given a task to work$/) do
  # Need something hooked before it starts working that will capture output messages
  out_message_exchange = "tef.#{@tef_env}.generic.worker_generated_messages"
  @capture_message_queue = @bunny_channel.queue('test_message_capture_queue')
  @capture_message_queue.bind(out_message_exchange, routing_key: '#')


  @test_task[:guid] = '112233'

  get_queue(@worker.in_queue_name).publish(@test_task.to_json)
end
