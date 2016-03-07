require 'tef/development/step_definitions/action_steps'


When(/^a manager is started$/) do
  options = {}
  options[:name_prefix] = @prefix if @prefix
  options[:in_queue] = @manager_queue_name if @manager_queue_name

  @manager = TEF::Manager::ManagerNode.new(options)
  @manager.start
end
