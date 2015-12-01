require 'tef/development/step_definitions/setup_steps'


Given(/^message in\/out queues for the Worker have not been yet been created$/) do
  @worker_queue_name = "tef.#{@tef_env}.worker.#{Socket.gethostname}"
  @keeper_queue_name = "tef.#{@tef_env}.keeper.#{'some_type'}"
  @manager_queue_name = "tef.#{@tef_env}.task_queue.control"

  get_queue(@worker_queue_name).delete if @bunny_connection.queue_exists?(@worker_queue_name)
  get_queue(@keeper_queue_name).delete if @bunny_connection.queue_exists?(@keeper_queue_name)
  get_queue(@manager_queue_name).delete if @bunny_connection.queue_exists?(@manager_queue_name)
end

And(/^a worker name of "([^"]*)"$/) do |name|
  @worker_name = name
end

And(/^a worker queue name of "([^"]*)"$/) do |queue_name|
  @worker_queue_name = queue_name
end

And(/^worker message queues are available$/) do
  # todo - This test could be less fragile if we set the queue names explicitly (in a
  # previous step) instead of relying on the default queue names (which could change)
  @worker_queue_name = "tef.#{@tef_env}.worker.#{Socket.gethostname}.#{Process.pid}"
  @keeper_queue_name = "tef.#{@tef_env}.keeper.generic"
  @manager_queue_name = "tef.#{@tef_env}.manager"

  @expected_queues = [@worker_queue_name, @keeper_queue_name, @manager_queue_name]

  @expected_queues.each do |queue_name|
    raise("Message queue #{queue_name} has not been created yet.") unless @bunny_connection.queue_exists?(queue_name)
  end
end
