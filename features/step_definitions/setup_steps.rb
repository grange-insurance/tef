require 'tef/development/step_definitions/setup_steps'


And(/^a local configured manager node is running$/) do
  here = File.dirname(__FILE__)
  path_to_manager_binary = "#{here}/../../bin/start_tef_configured_manager"

  # Assuming development on a Windows machine
  @manager_pid = Process.spawn("start \"Manager\" cmd /c bundle exec ruby #{path_to_manager_binary}")

  Process.detach(@manager_pid)
end

And(/^(?:"([^"]*)" )?local configured worker nodes are running$/) do |worker_count|
  # Assuming that the entire TEF project is present
  here = File.dirname(__FILE__)
  path_to_worker_binary = "#{here}/../../bin/start_tef_configured_worker"

  @worker_pids ||= []
  worker_count = worker_count ? worker_count.to_i : 5

  worker_count.times do
    # Assuming development on a Windows machine
    @worker_pids << Process.spawn("start \"Worker\" cmd /c bundle exec ruby #{path_to_worker_binary}")

    Process.detach(@worker_pids.last)
  end
end

And(/^a local configured keeper node is running$/) do
  here = File.dirname(__FILE__)
  path_to_keeper_binary = "#{here}/../../testing/start_tef_generic_keeper"

  # Assuming development on a Windows machine
  @keeper_pid = Process.spawn("start \"Keeper\" cmd /c bundle exec ruby #{path_to_keeper_binary}")
  Process.detach(@keeper_pid)
end

And(/^all components have finished starting up$/) do
  # Every component's message queue (except for workers who do not bind to exchanges) needs to exist
  manager_queue_name = "tef.#{@tef_env}.manager"
  wait_for { puts "Waiting for queue #{manager_queue_name} to be available..."; @bunny_connection.queue_exists?(manager_queue_name) }.to be true
  keeper_queue_name = "tef.#{@tef_env}.keeper.generic"
  wait_for { puts "Waiting for queue #{keeper_queue_name} to be available..."; @bunny_connection.queue_exists?(keeper_queue_name) }.to be true

  # And have a moment to hook them all up to exchanges
  sleep 1
end

