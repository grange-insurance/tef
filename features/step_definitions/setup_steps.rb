require 'tef/development/step_definitions/setup_steps'

And(/^a keeper node is running$/) do
  @keeper_pid = Process.spawn('start "Keeper" cmd /c bundle exec ruby testing\start_tef_generic_keeper')
  Process.detach(@keeper_pid)
end
