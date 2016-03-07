require 'socket'

Given(/^the following message queues have not been yet been created:$/) do |queue_names|
  @worker_type ||= 'some_worker_type'
  @keeper_type ||= 'some_keeper_type'
  queue_names = queue_names.raw.flatten.map { |name| name.sub('<env>', @tef_env).sub('<name>', Socket.gethostname).sub('<pid>', Process.pid.to_s).sub('<worker_type>', @worker_type).sub('<keeper_type>', @keeper_type) }

  queue_names.each do |queue_name|
    get_queue(queue_name).delete if @bunny_connection.queue_exists?(queue_name)
  end
end

Given(/^the following message exchanges have not been yet been created:$/) do |exchange_names|
  @worker_type ||= 'some_worker_type'
  exchange_names = exchange_names.raw.flatten.map { |name| name.sub('<env>', @tef_env).sub('<worker_type>', @worker_type) }

  exchange_names.each do |exchange_name|
    delete_exchange(exchange_name) if @bunny_connection.exchange_exists?(exchange_name)
  end
end

And(/^a name prefix of "([^"]*)"$/) do |prefix|
  @prefix = prefix
end

And(/^a keeper queue name of "([^"]*)"$/) do |queue_name|
  @keeper_queue_name = queue_name
end

And(/^a manager queue name of "([^"]*)"$/) do |queue_name|
  @manager_queue_name = queue_name
end

And(/^a local manager node is running$/) do
  # Assuming that the entire TEF project is present
  here = File.dirname(__FILE__)
  path_to_manager_binary = "#{here}/../../../../../tef-manager/bin/start_tef_manager"

  # Assuming development on a Windows machine
  @manager_pid = Process.spawn("start \"Manager\" cmd /c bundle exec ruby #{path_to_manager_binary}")

  Process.detach(@manager_pid)
end

And(/^a local worker node is running$/) do
  # Assuming that the entire TEF project is present
  here = File.dirname(__FILE__)
  path_to_worker_binary = "#{here}/../../../../../tef-worker/bin/start_tef_worker"

  # Assuming development on a Windows machine
  @worker_pid = Process.spawn("start \"Worker\" cmd /c bundle exec ruby #{path_to_worker_binary}")

  Process.detach(@worker_pid)
end

And(/^(?:"([^"]*)" )?local worker nodes are running$/) do |worker_count|
  # Assuming that the entire TEF project is present
  here = File.dirname(__FILE__)
  path_to_worker_binary = "#{here}/../../../../../tef-worker/bin/start_tef_worker"

  @worker_pids ||= []
  worker_count = worker_count ? worker_count.to_i : 5

  worker_count.times do
    # Assuming development on a Windows machine
    @worker_pids << Process.spawn("start \"Worker\" cmd /c bundle exec ruby #{path_to_worker_binary}")

    Process.detach(@worker_pids.last)
  end
end

And(/^no TEF nodes are running$/) do
  kill_existing_tef_processes
end
