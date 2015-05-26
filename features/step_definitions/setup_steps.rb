Given(/^a queuebert node is running$/) do
  @queuebert_pid = Process.spawn('start "Queuebert" cmd /c bundle exec start_tef_queuebert')
  Process.detach(@queuebert_pid)
end

And(/^a manager node is running$/) do
  @manager_pid = Process.spawn('start "Manager" cmd /c bundle exec start_tef_manager')
  Process.detach(@manager_pid)
end

And(/^a cuke worker node is running$/) do
  @cuke_worker_pid = Process.spawn('start "Cuke Worker" cmd /c bundle exec start_tef_cuke_worker')
  Process.detach(@cuke_worker_pid)
end

And(/^a cuke keeper node is running$/) do
  @cuke_keeper_pid = Process.spawn('start "Cuke Keeper" cmd /c bundle exec start_tef_cuke_keeper')
  Process.detach(@cuke_keeper_pid)
end

And(/^no TEF nodes are running$/) do
  kill_existing_tef_processes
end
