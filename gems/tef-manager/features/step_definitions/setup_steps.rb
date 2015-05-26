require_relative '../../../../features/step_definitions/common/setup_steps'


Given(/^message in\/out queues for the manager have not been yet been created$/) do
  @task_queue_name = "tef.#{@tef_env}.task_queue.control"
  @dispatcher_queue_name = "tef.#{@tef_env}.dispatcher.control"
  @worker_queue_name = "tef.#{@tef_env}.worker.control"

  @manager_queues = [@task_queue_name, @dispatcher_queue_name, @worker_queue_name]

  @manager_queues.each do |queue_name|
    puts "checking for queue: #{queue_name}"
    get_queue(queue_name).delete if @bunny_connection.queue_exists?(queue_name)
  end
  # get_queue(@task_queue_name).delete if @bunny_connection.queue_exists?(@task_queue_name)
  # get_queue(@dispatcher_queue_name).delete if @bunny_connection.queue_exists?(@dispatcher_queue_name)
  # get_queue(@worker_queue_name).delete if @bunny_connection.queue_exists?(@worker_queue_name)
end

And(/^a task queue queue name of "([^"]*)"$/) do |queue_name|
  @task_queue_name = queue_name
end

And(/^a dispatcher queue name of "([^"]*)"$/) do |queue_name|
  @dispatcher_queue_name = queue_name
end

And(/^a worker queue name of "([^"]*)"$/) do |queue_name|
  @worker_queue_name = queue_name
end

And(/^manager message queues are available$/) do
  # todo - This test could be less fragile if we set the queue names explicitly (in a
  # previous step) instead of relying on the default queue names (which could change)
  @task_queue_name = "tef.#{@tef_env}.task_queue.control"
  @dispatcher_queue_name = "tef.#{@tef_env}.dispatcher.control"
  @worker_queue_name = "tef.#{@tef_env}.worker.control"

  @expected_queues = [@task_queue_name, @dispatcher_queue_name, @worker_queue_name]

  @expected_queues.each do |queue_name|
    puts "checking for queue: #{queue_name}"
    raise("Message queue #{queue_name} has not been created yet.") unless @bunny_connection.queue_exists?(queue_name)
  end
end
