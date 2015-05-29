require_relative '../../../../features/step_definitions/common/setup_steps'


Given(/^message in\/out queues for the keeper have not been yet been created$/) do
  keeper_queues = [@keeper_queue_name, @outbound_queue_name].compact # Removing nils in case they haven't been set

  keeper_queues.each do |queue_name|
    get_queue(queue_name).delete if @bunny_connection.queue_exists?(queue_name)
  end
end

Given(/^a queue to receive from$/) do
  @mock_properties = create_mock_properties
  @mock_channel = create_mock_channel
  @fake_publisher = create_fake_publisher(@mock_channel)
end

Given(/^something with which to save results/) do
  @task_saver = TEF::Keeper::ResultSaver.new(@fake_publisher)
end

Given(/^the following result processing block:$/) do |code_block|
  code = "@task_saver.message_handling #{code_block}"
  eval(code)
end

Given(/^no result processing block has been defined$/) do
  @task_saver.instance_variable_set(:@handling_block, nil)
end

And(/^the keeper message queues are available$/) do
  @expected_queues = [@keeper_queue_name, @outbound_queue_name].compact # Removing nils in case they haven't been set

  @expected_queues.each do |queue_name|
    raise("Message queue #{queue_name} has not been created yet.") unless @bunny_connection.queue_exists?(queue_name)
  end
end

And(/^an out queue name of "([^"]*)"$/) do |queue_name|
  @outbound_queue_name = queue_name
end
