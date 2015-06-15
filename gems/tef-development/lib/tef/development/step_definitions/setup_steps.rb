require 'socket'

Given(/^the following message queues have not been yet been created:$/) do |queue_names|
  @worker_type ||= 'some_worker_type'
  @keeper_type ||= 'some_keeper_type'
  queue_names = queue_names.raw.flatten.map { |name| name.sub('<env>', @tef_env).sub('<name>', Socket.gethostname).sub('<pid>', Process.pid.to_s).sub('<worker_type>', @worker_type).sub('<keeper_type>', @keeper_type) }

  queue_names.each do |queue_name|
    get_queue(queue_name).delete if @bunny_connection.queue_exists?(queue_name)
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

And(/^a manager node is running$/) do
  @manager_pid = Process.spawn('start "Manager" cmd /c bundle exec start_tef_manager')
  Process.detach(@manager_pid)
end

And(/^a worker node is running$/) do
  @worker_pid = Process.spawn('start "Worker" cmd /c bundle exec start_tef_worker')
  Process.detach(@worker_pid)
end

And(/^(?:"([^"]*)" )?worker nodes are running$/) do |worker_count|
  @worker_pids ||= []
  worker_count = worker_count ? worker_count.to_i : 5

  worker_count.times do
    @worker_pids << Process.spawn('start "Worker" cmd /c bundle exec start_tef_worker')
    Process.detach(@worker_pids.last)
  end
end

And(/^no TEF nodes are running$/) do
  kill_existing_tef_processes
end
