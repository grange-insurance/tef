require_relative '../testing/mocks'
include TEF::Development::Testing::Mocks


shared_examples_for 'a messaging component, unit level' do |message_queues|

  before(:each) do
    @options = configuration.dup
    @options[:logger] = create_mock_logger

    @component = clazz.new(@options)
  end

  message_queues.each do |message_queue|
    it "knows the name of its message queue (#{message_queue}" do
      expect(@component).to respond_to("#{message_queue}_name")
    end
  end

end
