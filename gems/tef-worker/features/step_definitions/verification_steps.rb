require_relative '../../../../features/step_definitions/common/verification_steps'


Then(/^the worker name is "([^"]*)"$/) do |worker_name|
  worker_name = worker_name.sub('<machine_name>', Socket.gethostname).sub('<pid>', Process.pid.to_s)

  expect(@worker.name).to eq(worker_name)
end

Then(/^message in\/out queues for the Worker have been created$/) do
  expect(@bunny_connection.queue_exists?(@worker_queue_name)).to be true
  expect(@bunny_connection.queue_exists?(@keeper_queue_name)).to be true
  expect(@bunny_connection.queue_exists?(@manager_queue_name)).to be true
end

And(/^the worker can still receive and send messages through them$/) do
  worker_queue = get_queue(@worker_queue_name)
  keeper_queue = get_queue(@keeper_queue_name)
  manager_queue = get_queue(@manager_queue_name)

  # The only messages that we want are ones arriving after the restart
  empty_queue(worker_queue)
  empty_queue(keeper_queue)
  empty_queue(manager_queue)

  worker_queue.publish(JSON.generate(@test_task))

  # Give the tasks a moment to get there
  wait_for { keeper_queue.message_count }.not_to eq(0)

  received_task_results = []
  keeper_queue.message_count.times do
    received_task_results << keeper_queue.pop
  end

  payload_index = 2
  # todo - this will need fixing once we know what results should look like
  #puts "received results: #{received_task_results}"
  received_task_results.map! { |result| JSON.parse(result[payload_index], symbolize_names: true)[:guid] }.flatten!

  expect(received_task_results).to match_array([@test_task[:guid]])
  expect(manager_queue.message_count).to be > 0 # Should have gotten at least one update due to working a task (and possibly some heartbeats depending on the timing of things)
end

Then(/the task is worked and the results sent to a keeper$/) do
  queue = get_queue(@worker.out_queue_name)

  # Give the tasks a moment to get there
  wait_for { queue.message_count }.not_to eq(0)

  received_task_results = []
  queue.message_count.times do
    received_task_results << queue.pop
  end

  # todo - this will need fixing once we know what results should look like
  payload_index = 2
  received_task_results.map! { |result| JSON.parse(result[payload_index], symbolize_names: true)[:guid] }.flatten!

  expect(received_task_results).to match_array([@test_task[:guid]])
end
