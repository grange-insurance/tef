shared_examples_for 'a wrapper component, integration level' do |message_queue_names|

  describe 'unique wrapper behavior' do

    # 'clazz' must be defined by an including scope
    # 'configuration' must be defined by an including scope

    let(:mock_publisher) { create_mock_queue }
    let(:mock_queue) { create_mock_queue }
    let(:mock_logger) { create_mock_logger }

    let(:component) do
      configuration[:logger] = mock_logger
      clazz.new(configuration)
    end


    describe 'initial setup' do

      message_queue_names.each do |message_queue|

        it "can be given a queue object instead of a queue name for its message queue (#{message_queue})" do
          configuration[message_queue.to_sym] = mock_publisher

          begin
            expect {
              component = clazz.new(configuration)
              component.start
            }.to_not raise_error
          ensure
            component.stop
          end
        end

        it "stores the name of its message queue for later use (#{message_queue})" do
          configuration[message_queue.to_sym] = 'test_message_queue'
          component = clazz.new(configuration)

          begin
            component.start

            expect(component.send("#{message_queue}_name")).to eq('test_message_queue')
          ensure
            component.stop
          end
        end

        it "logs which message queue it created/connected to (#{message_queue})" do
          allow(mock_queue).to receive(:name).and_return('test message queue')
          configuration[message_queue.to_sym] = mock_queue
          configuration[:logger] = mock_logger
          component = clazz.new(configuration)

          begin
            component.start
          ensure
            component.stop
          end

          expected_header = message_queue.to_s.gsub('_', ' ')

          expect(mock_logger).to have_received(:info).with(/#{expected_header}: test message queue/i)
        end

      end

      describe 'configuration problems' do

        before(:each) do
          @old_method = Bunny::Channel.instance_method(:queue)

          # todo - DRY out all of these hacks into a handy temporary override method
          # Monkey patch Bunny to throw the error that we need for testing
          module Bunny
            class Channel
              def queue(*args)
                raise(Exception, 'something went wrong')
              end
            end
          end
        end

        # Making sure that our changes don't escape a test and ruin the rest of the suite
        after(:each) do
          Bunny::Channel.send(:define_method, :queue, @old_method)
        end

        message_queue_names.each do |message_queue|

          it "will exit if it cannot successfully create/connect to its message queue upon startup (#{message_queue})" do
            configuration[message_queue.to_sym] = 'test message queue'
            component = clazz.new(configuration)

            begin
              expect { component.start }.to terminate.with_code(3)
            ensure
              component.stop
            end
          end

          it "logs if it cannot successfully create/connect to its message queue (#{message_queue})" do
            configuration[message_queue.to_sym] = 'test message queue'
            configuration[:logger] = mock_logger
            component = clazz.new(configuration)

            begin
              component.start
            rescue SystemExit
            ensure
              component.stop
            end

            expect(mock_logger).to have_received(:error).with(/failed to create/i)
          end

        end

      end
    end

  end
end
