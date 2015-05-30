And(/^a manager node is running$/) do
  @manager_pid = Process.spawn('start "Manager" cmd /c bundle exec start_tef_manager')
  Process.detach(@manager_pid)
end

And(/^no TEF nodes are running$/) do
  kill_existing_tef_processes
end
