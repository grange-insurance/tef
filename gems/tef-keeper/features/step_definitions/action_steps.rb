require_relative '../../../../features/step_definitions/common/action_steps'


When(/^a keeper is started$/) do
  options = {}
  options[:keeper_type] = @keeper_type if @keeper_type
  options[:queue_prefix] = @prefix if @prefix
  options[:in_queue] = @keeper_queue_name if @keeper_queue_name
  options[:out_queue] = @outbound_queue_name if @outbound_queue_name
  options[:callback] = @test_callback if @test_callback

  @keeper = TEF::Keeper::Keeper.new(options)
  @keeper.start
end

When(/^the following task result has been received:$/) do |result_message|
  @fake_publisher.call('delivery_info', @mock_properties, result_message)
end

When(/^it is given a task result to handle$/) do
  @test_result[:guid] = '112233'

  get_queue(@keeper.in_queue_name).publish(@test_result.to_json)
end

When(/^it is given a task result to handle that will need to be requeued$/) do
  @test_result[:guid] = '112233'

  allow(@test_callback).to receive(:call).and_return(true)

  get_queue(@keeper.in_queue_name).publish(@test_result.to_json)
end
