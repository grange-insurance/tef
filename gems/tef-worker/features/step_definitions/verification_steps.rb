require 'tef/development/step_definitions/verification_steps'


Then(/^the worker name is "([^"]*)"$/) do |worker_name|
  worker_name = worker_name.sub('<machine_name>', Socket.gethostname).sub('<pid>', Process.pid.to_s)

  expect(@worker.name).to eq(worker_name)
end

Then(/^message queues for the Worker have been created$/) do
  in_queue_names = [@worker_queue_name, @manager_queue_name]

  in_queue_names.each do |queue_name|
    raise("Expected queue '#{queue_name}' to exist but it did not.") unless @bunny_connection.queue_exists?(queue_name)
  end
end

Then(/^message exchanges for the Worker have been created$/) do
  out_exchange_name = "tef.#{@tef_env}.generic.worker_generated_messages"

  raise("Expected exchange '#{out_exchange_name}' to exist but it did not.") unless @bunny_connection.exchange_exists?(out_exchange_name)
end

And(/^the worker can still receive and send messages through them$/) do
  out_message_exchange = get_exchange(@message_exchange_name)
  worker_queue = get_queue(@worker_queue_name)
  manager_queue = get_queue(@manager_queue_name)
  message_capture_queue = @bunny_channel.queue('test_message_capture_queue')
  message_capture_queue.bind(out_message_exchange, routing_key: '#')

  # The only messages that we want are ones arriving after the restart
  empty_queue(worker_queue)
  empty_queue(manager_queue)

  worker_queue.publish(JSON.generate(@test_task))

  # Give the tasks a moment to get there
  wait_for { message_capture_queue.message_count }.not_to eq(0)

  received_messages = []
  message_capture_queue.message_count.times do
    received_messages << message_capture_queue.pop
  end

  received_messages.map! { |message| JSON.parse(message[2], symbolize_names: true)[:guid] }

  expect(received_messages).to match_array([@test_task[:guid]])
  expect(manager_queue.message_count).to be > 0 # Should have gotten at least one update due to working a task (and possibly some heartbeats depending on the timing of things)
end

Then(/the task is worked and the results are routed with "([^"]*)"$/) do |message_route|
  # Give the messages a moment to get there
  wait_for { @capture_message_queue.message_count }.not_to eq(0)

  @received_messages = messages_from_queue(@capture_message_queue.name)

  task_message = @received_messages.select { |message| message[:body]['type'] == 'task' }.first

  expect(task_message[:delivery_info][:routing_key]).to eq(message_route)
  expect(task_message[:body]['guid']).to eq(@test_task[:guid])
end
