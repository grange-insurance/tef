require 'tef/development/step_definitions/verification_steps'


Then(/^the following data is stored for the result:$/) do |expected_properties|
  expected_properties = expected_properties.rows_hash
  result = TEF::Keeper::TaskResult.take

  expected_properties.each do |key, value|
    expect(result[key]).to eq(value)
  end
end

Then(/^no data is stored for the result$/) do
  result = TEF::Keeper::TaskResult.take

  expect(result).to be_nil
end

Then(/^message queues for the keeper have been created$/) do
  in_queue_name = @keeper_queue_name

  raise("Expected queue '#{in_queue_name}' to exist but it did not.") unless @bunny_connection.queue_exists?(in_queue_name)
end

Then(/^message exchanges for the keeper have been created$/) do
  out_exchange_name = "tef.#{@tef_env}.generic.keeper_generated_messages"

  raise("Expected exchange '#{out_exchange_name}' to exist but it did not.") unless @bunny_connection.exchange_exists?(out_exchange_name)
end

And(/^the keeper can still receive and send messages through them$/) do
  keeper_queue = get_queue(@keeper_queue_name)
  out_message_exchange = get_exchange(@output_exchange_name)
  message_capture_queue = @bunny_channel.queue('test_message_capture_queue')
  message_capture_queue.bind(out_message_exchange, routing_key: '#')

  # The only messages that we want are ones arriving after the restart
  empty_queue(keeper_queue)

  keeper_queue.publish(JSON.generate(@test_result))

  # Give the results a moment to get there
  wait_for { message_capture_queue.message_count }.not_to eq(0)

  received_messages = []
  message_capture_queue.message_count.times do
    received_messages << message_capture_queue.pop
  end

  payload_index = 2
  received_messages.map! { |result| JSON.parse(result[payload_index], symbolize_names: true)[:guid] }.flatten!

  expect(received_messages).to match_array([@test_result[:guid]])
end

Then(/the result is handled/) do
  # todo - a fast but reliable method would be preferable instead of a sleep right here
  # Give the results a moment to be processed
  sleep 0.25

  expect(@test_callback).to have_received(:call)
end

And(/the result is forwarded and routed with "([^"]*)"$/) do |message_route|
  # Give the messages a moment to get there
  wait_for { @capture_message_queue.message_count }.not_to eq(0)

  @received_messages = messages_from_queue(@capture_message_queue.name)

  forwarded_message = @received_messages.first
  expect(forwarded_message[:delivery_info][:routing_key]).to eq(message_route)
  expect(forwarded_message[:body]['guid']).to eq(@test_result[:guid])
end
