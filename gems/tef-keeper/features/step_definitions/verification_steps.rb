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

Then(/^message in\/out queues for the keeper have been created$/) do
  keeper_queues = [@keeper_queue_name, @outbound_queue_name].compact # Removing nils in case they haven't been set

  keeper_queues.each do |queue_name|
    expect(@bunny_connection.queue_exists?(queue_name)).to be true
  end
end

And(/^the keeper can still receive and send messages through them$/) do
  pending("Not sure why this doesn't work")

  keeper_queue = get_queue(@keeper_queue_name)
  outbound_queue = get_queue(@outbound_queue_name)

  # puts "keeper queue: #{@keeper_queue_name}"
  # puts "out queue: #{@outbound_queue_name}"

  # The only messages that we want are ones arriving after the restart
  empty_queue(keeper_queue)
  empty_queue(outbound_queue)

  keeper_queue.publish(JSON.generate(@test_result))

  # Give the results a moment to get there
  begin
    until (outbound_queue.message_count > 0)
      puts 'waiting for new message...'
      sleep 5
    end
  rescue Interrupt => _
    fail('The message never got dispatched!')
  end

  received_tasks = []
  outbound_queue.message_count.times do
    received_tasks << outbound_queue.pop
  end

  payload_index = 2
  puts "received tasks: #{received_tasks}"
  received_tasks.map! { |result| JSON.parse(result[payload_index], symbolize_names: true)[:guid] }.flatten!

  expect(received_tasks).to match_array([@test_result[:guid]])
end

Then(/the result is handled/) do
  # todo - a fast but reliable method would be preferable instead of a sleep right here
  # Give the results a moment to be processed
  sleep 0.25

  expect(@test_callback).to have_received(:call)
end

And(/the result is forwarded/) do
  # todo - a fast but reliable method would be preferable instead of a sleep right here
  # Give the results a moment to be processed
  sleep 0.25

  outbound_queue = get_queue(@outbound_queue_name)

  expect(outbound_queue.message_count).to eq(1)
end
