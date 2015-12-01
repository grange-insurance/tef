require 'tef/development/step_definitions/setup_steps'


Given(/^message in\/out queues for the manager have not been yet been created$/) do
  @input_queue_name = "tef.#{@tef_env}.manager"

  @manager_queues = [@input_queue_name]

  @manager_queues.each do |queue_name|
    puts "checking for queue: #{queue_name}"
    get_queue(queue_name).delete if @bunny_connection.queue_exists?(queue_name)
  end
end

And(/^a manager queue queue name of "([^"]*)"$/) do |queue_name|
  @manager_queue_name = queue_name
end

And(/^manager message queues are available$/) do
  # todo - This test could be less fragile if we set the queue names explicitly (in a
  # previous step) instead of relying on the default queue names (which could change)
  @manager_queue_name = "tef.#{@tef_env}.manager"

  @expected_queues = [@manager_queue_name]

  @expected_queues.each do |queue_name|
    raise("Message queue #{queue_name} has not been created yet.") unless @bunny_connection.queue_exists?(queue_name)
  end
end
