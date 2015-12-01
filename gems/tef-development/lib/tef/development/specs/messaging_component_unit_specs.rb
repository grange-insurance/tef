shared_examples_for 'a messaging component, unit level' do |message_queues|

  # 'clazz' must be defined by an including scope
  # 'configuration' must be defined by an including scope

  let(:component) { clazz.new(configuration) }


  message_queues.each do |message_queue|
    # No special behavior at the moment.
  end

end
