require 'tef/development/step_definitions/setup_steps'


Given(/^message queues for the Worker have not yet been created$/) do
  @worker_queue_name = "tef.#{@tef_env}.worker.#{Socket.gethostname}"
  @manager_queue_name = "tef.#{@tef_env}.manager"
  in_queue_names = [@worker_queue_name, @manager_queue_name]

  in_queue_names.each do |queue_name|
    delete_queue(queue_name) if @bunny_connection.queue_exists?(queue_name)
  end
end

Given(/^message exchanges for the Worker have not yet been created$/) do
  out_exchange_name = "tef.#{@tef_env}.generic.worker_generated_messages"

  delete_exchange(out_exchange_name) if @bunny_connection.exchange_exists?(out_exchange_name)
end

And(/^a worker name of "([^"]*)"$/) do |name|
  @worker_name = name
end

And(/^a worker queue name of "([^"]*)"$/) do |queue_name|
  @worker_queue_name = queue_name
end

And(/^an output exchange name of "([^"]*)"$/) do |exchange_name|
  @output_exchange_name = exchange_name
end

And(/^worker message queues are available$/) do
  # todo - This test could be less fragile if we set the queue names explicitly (in a
  # previous step) instead of relying on the default queue names (which could change)
  @worker_queue_name = "tef.#{@tef_env}.worker.#{Socket.gethostname}.#{Process.pid}"
  @manager_queue_name = "tef.#{@tef_env}.manager"

  @expected_queues = [@worker_queue_name, @manager_queue_name]

  @expected_queues.each do |queue_name|
    raise("Message queue #{queue_name} has not been created yet.") unless @bunny_connection.queue_exists?(queue_name)
  end
end

And(/^worker message exchanges are available$/) do
  @message_exchange_name = "tef.#{@tef_env}.generic.worker_generated_messages"

  @expected_exchanges = [@message_exchange_name]

  @expected_exchanges.each do |exchange_name|
    raise("Message exchange #{exchange_name} has not been created yet.") unless @bunny_connection.exchange_exists?(exchange_name)
  end
end
