require_relative '../../../../features/step_definitions/common/action_steps'


When(/^a manager is started$/) do
  options = {}
  options[:queue_prefix] = @prefix if @prefix
  options[:task_queue] = @task_queue_name if @task_queue_name
  options[:dispatcher_queue] = @dispatcher_queue_name if @dispatcher_queue_name
  options[:worker_queue] = @worker_queue_name if @worker_queue_name

  @manager = TEF::Manager::ManagerNode.new(options)
  @manager.start
end

# When(/^it is given a task to work$/) do
#   @test_task[:guid] = '112233'
#
#   get_queue(@worker.in_queue_name).publish(@test_task.to_json)
# end
