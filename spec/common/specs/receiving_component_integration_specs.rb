require_relative 'messaging_component_integration_specs'

require_relative '../../../testing/mocks'
include TefTestingMocks


shared_examples_for 'a receiving component, integration level' do |clazz, configuration, input_queues|

  it_should_behave_like 'a messaging component, integration level', input_queues do
    let(:clazz) { clazz }
    let(:configuration) { configuration }
  end


  before(:each) do
    @mock_publisher = create_mock_queue
    @mock_channel = create_mock_channel
    @fake_input_queue = create_fake_publisher(@mock_channel)
    @options = configuration.dup

    @component = clazz.new(@options)
  end

  describe 'initial setup' do

    input_queues.each do |queue_name|
      it "should be listening to its queue (#{queue_name})" do
        @options[queue_name.to_sym] = @mock_publisher
        @component = clazz.new(@options)

        begin
          @component.start

          expect(@mock_publisher).to have_received(:subscribe_with)
        ensure
          @component.stop
        end
      end
    end

  end

  describe 'message handling' do

    input_queues.each do |queue_name|
      it "acknowledges messages from its queue (#{queue_name}) when it is finished with them" do
        delivery_info = create_mock_delivery_info
        @options[queue_name.to_sym] = @fake_input_queue
        component = clazz.new(@options)

        begin
          component.start

          # A bad messages is enough for a quick test. Assuming that the component can handle bad messages gracefully...
          @fake_input_queue.call(delivery_info, create_mock_properties, 'this is not json')


          expect(@mock_channel).to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
        ensure
          component.stop
        end
      end
    end

  end

end
