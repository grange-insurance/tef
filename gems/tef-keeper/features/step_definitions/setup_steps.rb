require 'tef/development/step_definitions/setup_steps'


Given(/^message queues for the keeper have not yet been created$/) do
  @keeper_queue_name = "tef.#{@tef_env}.keeper.generic"
  in_queue_name = @keeper_queue_name

  delete_queue(in_queue_name) if @bunny_connection.queue_exists?(in_queue_name)
end

Given(/^message exchanges for the keeper have not yet been created$/) do
  out_exchange_name = "tef.#{@tef_env}.generic.keeper_generated_messages"

  delete_exchange(out_exchange_name) if @bunny_connection.exchange_exists?(out_exchange_name)
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
  @keeper_queue_name ||= "tef.#{@tef_env}.keeper.generic"

  @expected_queues = [@keeper_queue_name].compact # Removing nils in case they haven't been set

  @expected_queues.each do |queue_name|
    raise("Message queue #{queue_name} has not been created yet.") unless @bunny_connection.queue_exists?(queue_name)
  end
end

And(/^the keeper message exchanges are available$/) do
  @output_exchange_name ||= "tef.#{@tef_env}.generic.keeper_generated_messages"

  @expected_exchanges = [@output_exchange_name].compact # Removing nils in case they haven't been set

  @expected_exchanges.each do |queue_name|
    raise("Message queue #{queue_name} has not been created yet.") unless @bunny_connection.exchange_exists?(queue_name)
  end
end

And(/^an output exchange name of "([^"]*)"$/) do |queue_name|
  @output_exchange_name = queue_name
end
