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
