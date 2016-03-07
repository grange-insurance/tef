require 'tef/development/step_definitions/verification_steps'

And(/^the result for the executed tasks are handled by the keeper$/) do
  # Give the messages a moment to get there
  wait_for { @capture_message_queue.message_count }.to eq(@explicit_test_tasks.count)

  received_messages = messages_from_queue(@capture_message_queue.name)
  received_messages.map! { |task| task[:body]['guid'] }.flatten

  expect(received_messages).to match_array(@explicit_test_tasks)
end
