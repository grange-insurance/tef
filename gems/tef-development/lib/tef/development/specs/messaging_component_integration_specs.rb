require_relative '../testing/custom_matchers'
require_relative '../testing/mocks'
include TEF::Development::Testing::Mocks


shared_examples_for 'a messaging component, integration level' do |message_queues|

  before(:each) do
    @options = configuration.dup

    @mock_logger = create_mock_logger
    @mock_publisher = create_mock_queue

    @options[:logger] = @mock_logger
    @component = clazz.new(@options)
  end


  describe 'initial setup' do

    message_queues.each do |message_queue|
      it "can be given a queue object instead of a queue name for its message queue (#{message_queue})" do
        @options[message_queue.to_sym] = @mock_publisher

        begin
          expect { @component = clazz.new(@options)
          @component.start
          }.to_not raise_error
        ensure
          @component.stop
        end
      end
    end

    message_queues.each do |message_queue|
      it "stores the name of its message queue for later use (#{message_queue})" do
        @options[message_queue.to_sym] = 'test_message_queue'
        @component = clazz.new(@options)

        begin
          @component.start

          expect(@component.send("#{message_queue}_name")).to eq('test_message_queue')
        ensure
          @component.stop
        end
      end
    end

    message_queues.each do |message_queue|
      it "logs which message queue it created/connected to (#{message_queue})" do
        @options[message_queue.to_sym] = 'test message queue'
        @component = clazz.new(@options)

        begin
          @component.start
        rescue SystemExit
        ensure
          @component.stop
        end

        expected_header = message_queue.to_s.gsub('_', ' ')

        expect(@mock_logger).to have_received(:info).with(/#{expected_header}: test message queue/i)
      end
    end

  end


  describe 'configuration problems' do

    before(:each) do
      @env_location = 'TEF_ENV'
      @url_location = 'TEF_AMQP_URL_TEMP'
      @old_env = ENV[@env_location]
      @old_url = ENV[@url_location]

      @old_method = Bunny::Channel.instance_method(:queue)
    end

    # Making sure that our changes don't escape a test and ruin the rest of the suite
    after(:each) do
      ENV[@env_location] = @old_env
      ENV[@url_location] = @old_url

      Bunny::Channel.send(:define_method, :queue, @old_method)
    end


    message_queues.each do |message_queue|
      it "will exit if it cannot successfully create/connect to its message queue (#{message_queue})" do
        # todo - DRY out all of these hacks into a handy temporary override method
        # Monkey patch Bunny to throw the error that we need for testing
        module Bunny
          class Channel
            def queue(*args)
              raise(Exception, 'something went wrong')
            end
          end
        end

        @options[message_queue.to_sym] = 'test message queue'
        @component = clazz.new(@options)

        begin
          expect { @component.start }.to terminate.with_code(3)
        ensure
          @component.stop
        end
      end
    end

    message_queues.each do |message_queue|
      it "logs if it cannot successfully create/connect to its message queue (#{message_queue})" do
        # todo - DRY out all of these hacks into a handy temporary override method
        # Monkey patch Bunny to throw the error that we need for testing
        module Bunny
          class Channel
            def queue(*args)
              raise(Exception, 'something went wrong')
            end
          end
        end

        @options[message_queue.to_sym] = 'test message queue'
        @component = clazz.new(@options)

        begin
          @component.start
        rescue SystemExit
        ensure
          @component.stop
        end

        expect(@mock_logger).to have_received(:error).with(/failed to create/i)
      end
    end

  end
end
