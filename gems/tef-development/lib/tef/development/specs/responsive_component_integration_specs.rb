require_relative '../testing/mocks'
include TEF::Development::Testing::Mocks

# Could be unit or integration level depending on where the tests are called
# from and what #start/#stop does
shared_examples_for 'a responsive component, integration level' do |queue_param_names, spec_config|

  describe 'common responsive behavior' do
    it_should_behave_like 'a receiving component, integration level', queue_param_names
  end

  describe 'unique responsive behavior' do

    let(:needs_started) { spec_config[:needs_started] }
    let(:mock_exchange) { create_mock_exchange }
    let(:mock_channel) { create_mock_channel(mock_exchange) }
    let(:message_queue) { create_fake_publisher(mock_channel) }


    describe 'message handling' do

      queue_param_names.each do |queue_name|

        it 'can gracefully handle non-JSON messages' do
          # configuration and clazz must be defined externally
          configuration[queue_name.to_sym] = message_queue
          component = clazz.new(configuration)

          begin
            component.start if needs_started

            expect { message_queue.call(create_mock_delivery_info, create_mock_properties, 'this is not json') }.to_not raise_error
          ensure
            component.stop if needs_started
          end
        end

        it 'logs when it receives a non-JSON message' do
          # configuration and clazz  must be defined externally
          configuration[queue_name.to_sym] = message_queue
          component = clazz.new(configuration)

          begin
            component.start if needs_started

            message_queue.call(create_mock_delivery_info, create_mock_properties, 'this is not json')

            expect(mock_logger).to have_received(:error).with(/MESSAGE_ERROR\|INVALID_JSON\|\d+: unexpected token at 'this is not json'\|this is not json/)
          ensure
            component.stop if needs_started
          end
        end

        it 'replies to non-JSON messages with the caught error if requested' do
          properties = create_mock_properties(:reply_to => 'some queue')
          # configuration and clazz  must be defined externally
          configuration[queue_name.to_sym] = message_queue
          component = clazz.new(configuration)

          begin
            component.start if needs_started

            message_queue.call(create_mock_delivery_info, properties, 'this is not json')

            expect(mock_exchange).to have_received(:publish).with(/"response":.*MESSAGE_ERROR\|INVALID_JSON\|\d+: unexpected token at 'this is not json'\|this is not json/, {:routing_key => properties.reply_to, :correlation_id => properties.correlation_id})
          ensure
            component.stop if needs_started
          end
        end

        it 'does not reply to non-JSON messages with the caught error if not requested' do
          properties = create_mock_properties(:reply_to => nil)
          # configuration and clazz  must be defined externally
          configuration[queue_name.to_sym] = message_queue
          component = clazz.new(configuration)

          begin
            component.start if needs_started

            message_queue.call(create_mock_delivery_info, properties, 'this is not json')

            expect(mock_exchange).to_not have_received(:publish)
          ensure
            component.stop if needs_started
          end
        end

        it 'does not reply to non-JSON messages if no correlation id is provided' do
          properties = create_mock_properties(:reply_to => 'some queue', :correlation_id => nil)
          # configuration and clazz  must be defined externally
          configuration[queue_name.to_sym] = message_queue
          component = clazz.new(configuration)

          begin
            component.start if needs_started

            message_queue.call(create_mock_delivery_info, properties, 'this is not json')

            expect(mock_exchange).to_not have_received(:publish)
          ensure
            component.stop if needs_started
          end
        end

        it "acknowledges messages from its queue (#{queue_name}) when it is finished with them" do
          delivery_info = create_mock_delivery_info
          # configuration and clazz  must be defined externally
          configuration[queue_name.to_sym] = message_queue
          component = clazz.new(configuration)

          begin
            component.start if needs_started

            # A bad messages is enough for a quick test.
            message_queue.call(delivery_info, create_mock_properties, 'this is not json')


            expect(mock_channel).to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
          ensure
            component.stop if needs_started
          end
        end
      end

    end

  end
end
