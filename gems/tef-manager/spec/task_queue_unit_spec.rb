require 'spec_helper'
require 'json'

describe 'TaskQueue, Unit' do

  clazz = TEF::Manager::TaskQueue

  it_should_behave_like 'a strictly configured component', clazz

  describe 'instance level' do

    before(:each) do
      @test_task = {type: "task", task_type: "type_1", guid: "guid1", priority: 5, resources: "pipe|delminated|list", task_data: "ew0KICAibWVzc2FnZSI6ICJIZWxsbyBXb3JsZCINCn0="}

      @mock_logger = create_mock_logger
      @mock_input_queue = create_mock_queue
      @mock_exchange = create_mock_exchange
      @mock_channel = create_mock_channel(@mock_exchange)

      @options = {
          logger: @mock_logger,
          input_queue: @mock_input_queue
      }

      @task_queue = clazz.new(@options)
    end


    it_should_behave_like 'a logged component, unit level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end

    it 'will complain if not provided a with an input queue' do
      @options.delete(:input_queue)

      expect { clazz.new(@options) }.to raise_error(ArgumentError, /must be provided/i)
    end

    it 'does not change the progname on the logger' do
      expect(@mock_logger).not_to receive(:progname=)
    end

    it 'can store a task' do
      expect(@task_queue).to respond_to(:push)
    end

    it 'needs a task to store' do
      expect(@task_queue.method(:push).arity).to eq(1)
    end

    it 'can retrieve a task' do
      expect(@task_queue).to respond_to(:pop)
    end

    it 'retrieves a task based on resource availability and worker types' do
      expect(@task_queue.method(:pop).arity).to eq(2)
    end

    it 'has an input queue' do
      expect(@task_queue).to respond_to(:input_queue)
    end

    it 'subscribes to its input queue' do
      expect(@mock_input_queue).to have_received(:subscribe_with)
    end

    describe 'message handling' do

      it 'acknowledges the messages that it handles' do
        delivery_info = create_mock_delivery_info
        input_queue = create_fake_publisher(@mock_channel)
        @options[:input_queue] = input_queue

        clazz.new(@options)
        # A bad messages is enough for a quick unit test
        input_queue.call(delivery_info, create_mock_properties, 'this is not json')

        expect(@mock_channel).to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
      end

    end

    describe 'bad message handling' do

      it 'can gracefully handle non-JSON messages' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue

        clazz.new(@options)

        expect { input_queue.call(create_mock_delivery_info, create_mock_properties, 'this is not json') }.to_not raise_error
      end

      it 'logs when it receives a non-JSON message' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, create_mock_properties, 'this is not json')

        expect(@mock_logger).to have_received(:error).with(/INPUT_FAILED\|PARSE_JSON\|\d+: unexpected token at 'this is not json'\|this is not json/)
      end

      it 'replies to non-JSON messages with the caught error if requested' do
        properties = create_mock_properties(reply_to: 'some queue')
        input_queue = create_fake_publisher(@mock_channel)
        @options[:input_queue] = input_queue

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, properties, 'this is not json')

        expect(@mock_exchange).to have_received(:publish).with(/"response":.*INPUT_FAILED\|PARSE_JSON\|\d+: unexpected token at 'this is not json'\|this is not json/, {routing_key: properties.reply_to, correlation_id: properties.correlation_id})
      end

      it 'does not reply to non-JSON messages with the caught error if not requested' do
        properties = create_mock_properties(reply_to: nil)
        input_queue = create_fake_publisher(@mock_channel)
        @options[:input_queue] = input_queue

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, properties, 'this is not json')

        expect(@mock_exchange).to_not have_received(:publish)
      end

      it 'will not accept JSON messages without a type on the input queue' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue
        @test_task.delete(:type)

        clazz.new(@options)

        expect { input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task)) }.to_not raise_error
      end

      it 'logs when it receives a JSON messages without a type' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue
        @test_task.delete(:type)

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        expect(@mock_logger).to have_received(:error).with(/INPUT_FAILED\|INVALID_JSON\|NO_TYPE\|/)
      end

      it 'replies to JSON messages without a type with the caught error if requested' do
        properties = create_mock_properties(reply_to: 'some queue')
        input_queue = create_fake_publisher(@mock_channel)
        @options[:input_queue] = input_queue
        @test_task.delete(:type)

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

        expect(@mock_exchange).to have_received(:publish).with(/"response":.*INPUT_FAILED\|INVALID_JSON\|NO_TYPE\|/, {routing_key: properties.reply_to, correlation_id: properties.correlation_id})
      end

      it 'does not reply to JSON messages without a type with the caught error if not requested' do
        properties = create_mock_properties(reply_to: nil)
        input_queue = create_fake_publisher(@mock_channel)
        @options[:input_queue] = input_queue
        @test_task.delete(:type)

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

        expect(@mock_exchange).to_not have_received(:publish)
      end

      it 'can gracefully handle message handling errors' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue
        @test_task[:type] = 'a problematic task'

        clazz.new(@options)

        expect { input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task)) }.to_not raise_error
      end

      it 'logs when it has a message handling error' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue
        @test_task[:type] = 'a problematic task'

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        expect(@mock_logger).to have_received(:error).with(/INPUT_FAILED\|CALL_FAILED\|a problematic task\|undefined method.*/)
      end

      it 'replies to erroneously handle messages with the caught error if requested' do
        properties = create_mock_properties(reply_to: 'some queue')
        input_queue = create_fake_publisher(@mock_channel)
        @options[:input_queue] = input_queue
        @test_task[:type] = 'a problematic task'

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

        expect(@mock_exchange).to have_received(:publish).with(/"response":.*INPUT_FAILED\|CALL_FAILED\|a problematic task\|undefined method.*/, {routing_key: properties.reply_to, correlation_id: properties.correlation_id})
      end

      it 'does not reply to erroneously handle messages if not requested' do
        properties = create_mock_properties(reply_to: nil)
        input_queue = create_fake_publisher(@mock_channel)
        @options[:input_queue] = input_queue
        @test_task[:type] = 'a problematic task'

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

        expect(@mock_exchange).to_not have_received(:publish)
      end

      it 'replies with a JSON hash' do
        properties = create_mock_properties(reply_to: 'some queue')
        fake_exchange = create_fake_exchange
        input_queue = create_fake_publisher(create_mock_channel(fake_exchange))
        @options[:input_queue] = input_queue

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, properties, 'this is not json')

        response = fake_exchange.messages.first
        expect(JSON.parse(response)).to be_a(Hash)
      end

    end

  end
end
