require_relative '../../../testing/mocks'
include TefTestingMocks

# Could be unit or integration level depending on where the tests are called
# from and what #start/#stop does
shared_examples_for 'a message controlled component' do |clazz, queue_param_name|

  before(:each) do
    @test_task = test_task.dup

    @mock_logger = create_mock_logger
    @mock_exchange = create_mock_exchange
    @mock_channel = create_mock_channel(@mock_exchange)
    @control_queue = create_fake_publisher(@mock_channel)

    @options = configuration.dup
    @options[queue_param_name] = @control_queue
    @options[:logger] = @mock_logger

    @component = clazz.new(@options)
  end

  it 'acknowledges the messages that it handles' do
    delivery_info = create_mock_delivery_info

    begin
      @component.start if needs_started

      # A bad messages is enough for a quick unit test
      @control_queue.call(delivery_info, create_mock_properties, 'this is not json')

      expect(@mock_channel).to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
    ensure
      @component.stop if needs_started
    end
  end


  it 'can gracefully handle non-JSON messages' do
    begin
      @component.start if needs_started

      expect { @control_queue.call(create_mock_delivery_info, create_mock_properties, 'this is not json') }.to_not raise_error
    ensure
      @component.stop if needs_started
    end
  end

  it 'logs when it receives a non-JSON message' do
    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, create_mock_properties, 'this is not json')

      expect(@mock_logger).to have_received(:error).with(/CONTROL_FAILED\|PARSE_JSON\|\d+: unexpected token at 'this is not json'\|this is not json/)
    ensure
      @component.stop if needs_started
    end
  end

  it 'replies to non-JSON messages with the caught error if requested' do
    properties = create_mock_properties(:reply_to => 'some queue')

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, properties, 'this is not json')

      expect(@mock_exchange).to have_received(:publish).with(/"response":.*CONTROL_FAILED\|PARSE_JSON\|\d+: unexpected token at 'this is not json'\|this is not json/, {:routing_key => properties.reply_to, :correlation_id => properties.correlation_id})
    ensure
      @component.stop if needs_started
    end
  end

  it 'does not reply to non-JSON messages with the caught error if not requested' do
    properties = create_mock_properties(:reply_to => nil)

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, properties, 'this is not json')

      expect(@mock_exchange).to_not have_received(:publish)
    ensure
      @component.stop if needs_started
    end
  end

  it 'does not replies to non-JSON messages if no correlation id is provided' do
    properties = create_mock_properties(:reply_to => 'some queue', :correlation_id => nil)

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, properties, 'this is not json')

      expect(@mock_exchange).to_not have_received(:publish)
    ensure
      @component.stop if needs_started
    end
  end

  it 'can gracefully handle JSON messages without a type on its control queue' do
    @test_task.delete(:type)

    begin
      @component.start if needs_started

      expect { @control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task)) }.to_not raise_error
    ensure
      @component.stop if needs_started
    end
  end

  it 'logs when it receives a JSON messages without a type' do
    @test_task.delete(:type)

    message_json = JSON.generate(@test_task)

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, create_mock_properties, message_json)

      expect(@mock_logger).to have_received(:error).with(/CONTROL_FAILED\|INVALID_JSON\|NO_TYPE\|#{message_json}/)
    ensure
      @component.stop if needs_started
    end
  end

  it 'replies to JSON messages without a type with the caught error if requested' do
    properties = create_mock_properties(:reply_to => 'some queue')
    @test_task.delete(:type)

    begin
      @component.start if needs_started
      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      expect(@mock_exchange).to have_received(:publish).with(/"response":.*CONTROL_FAILED\|INVALID_JSON\|NO_TYPE\|/, {:routing_key => properties.reply_to, :correlation_id => properties.correlation_id})
    ensure
      @component.stop if needs_started
    end
  end

  it 'does not reply to JSON messages without a type with the caught error if not requested' do
    properties = create_mock_properties(:reply_to => nil)
    @test_task.delete(:type)

    begin
      @component.start if needs_started
      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      expect(@mock_exchange).to_not have_received(:publish)
    ensure
      @component.stop if needs_started
    end
  end

  it 'does not reply to JSON messages without a type if no correlation id is provided' do
    properties = create_mock_properties(:reply_to => 'some queue', :correlation_id => nil)
    @test_task.delete(:type)

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      expect(@mock_exchange).to_not have_received(:publish)
    ensure
      @component.stop if needs_started
    end
  end


  it 'can gracefully handle message handling errors' do
    @test_task[:type] = 'a problematic task'

    begin
      @component.start if needs_started

      expect { @control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task)) }.to_not raise_error
    ensure
      @component.stop if needs_started
    end
  end

  it 'logs when it has a message handling error' do
    @test_task[:type] = 'a problematic task'

    begin
      @component.start if needs_started
      @control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

      expect(@mock_logger).to have_received(:error).with(/CONTROL_FAILED\|CALL_FAILED\|a problematic task\|undefined method.*/)
    ensure
      @component.stop if needs_started
    end
  end

  it 'replies to erroneously handled messages with the caught error if requested' do
    properties = create_mock_properties(:reply_to => 'some queue')
    @test_task[:type] = 'a problematic task'

    begin
      @component.start if needs_started
      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      expect(@mock_exchange).to have_received(:publish).with(/"response":.*CONTROL_FAILED\|CALL_FAILED\|a problematic task\|undefined method.*/, {:routing_key => properties.reply_to, :correlation_id => properties.correlation_id})
    ensure
      @component.stop if needs_started
    end
  end

  it 'does not reply to erroneously handled messages if not requested' do
    properties = create_mock_properties(:reply_to => nil)
    @test_task[:type] = 'a problematic task'

    begin
      @component.start if needs_started
      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      expect(@mock_exchange).to_not have_received(:publish)
    ensure
      @component.stop if needs_started
    end
  end

  it 'does not reply to erroneously handled messages if no correlation id is provided' do
    properties = create_mock_properties(:reply_to => 'some queue', :correlation_id => nil)
    @test_task[:type] = 'a problematic task'

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      expect(@mock_exchange).to_not have_received(:publish)
    ensure
      @component.stop if needs_started
    end
  end

  it 'replies with a JSON hash' do
    properties = create_mock_properties(:reply_to => 'some queue')
    fake_exchange = create_fake_exchange
    control_queue = create_fake_publisher(create_mock_channel(fake_exchange))
    @options[queue_param_name] = control_queue

    component = clazz.new(@options)

    begin
      component.start if needs_started
      control_queue.call(create_mock_delivery_info, properties, 'this is not json')

      response = fake_exchange.messages.first
      expect(JSON.parse(response)).to be_a(Hash)
    ensure
      component.stop if needs_started
    end
  end

  it 'passes hash payloads unmolested when replying' do
    control_queue = create_mock_queue(@mock_channel)
    mock_properties = create_mock_properties
    payload = {:response => 'this is a hash'}

    @component.reply_if_requested(control_queue, mock_properties, payload)

    expect(@mock_exchange).to have_received(:publish).with('{"response":"this is a hash"}', :routing_key => 'reply_to1', :correlation_id => 'correlation_id1')
  end

  it 'creates a response hash for non-hash payloads' do
    control_queue = create_mock_queue(@mock_channel)
    mock_properties = create_mock_properties

    payload = 'this is not a hash'
    expect { @component.reply_if_requested(control_queue, mock_properties, payload) }.to_not raise_error

    expect(@mock_exchange).to have_received(:publish).with('{"response":"this is not a hash"}', :routing_key => 'reply_to1', :correlation_id => 'correlation_id1')
  end

  it 'replies to replies to successful messages if requested' do
    properties = create_mock_properties(:reply_to => 'some queue')

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      # The message needs to have been successful...
      expect(@mock_logger).to_not have_received(:error)

      expect(@mock_exchange).to have_received(:publish).with(/"response":/, {:routing_key => properties.reply_to, :correlation_id => properties.correlation_id})
    ensure
      @component.stop if needs_started
    end
  end

  it 'does not reply to successful messages if not requested' do
    properties = create_mock_properties(:reply_to => nil)

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      # The message needs to have been successful...
      expect(@mock_logger).to_not have_received(:error)

      expect(@mock_exchange).to_not have_received(:publish)
    ensure
      @component.stop if needs_started
    end
  end

  it 'does not reply to successful messages if no correlation id is provided' do
    properties = create_mock_properties(:reply_to => 'some queue', :correlation_id => nil)

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      expect(@mock_exchange).to_not have_received(:publish)
    ensure
      @component.stop if needs_started
    end
  end

  # todo - I'm not sure why which channel it uses is important
  it 'uses the default channel from the control queue when replying' do
    properties = create_mock_properties(:reply_to => 'some queue')

    begin
      @component.start if needs_started

      @control_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

      expect(@mock_channel).to have_received(:default_exchange)
    ensure
      @component.stop if needs_started
    end
  end


end
