require 'tef/development/step_definitions/verification_steps'

And(/^the result for the executed tasks are handled by the keeper$/) do
  output_queue_name = "keeper.test.output"

  queue = get_queue(output_queue_name)

  # Give the output a moment to get there
  wait_for { queue.message_count }.to eq(@explicit_test_tasks.count)

  received_test_tasks = []
  queue.message_count.times do
    received_test_tasks << queue.pop
  end

  received_test_tasks.map! { |task| JSON.parse(task[2], symbolize_names: true)[:guid] }.flatten

  expect(received_test_tasks).to match_array(@explicit_test_tasks)
end
